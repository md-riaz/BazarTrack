<?php

declare(strict_types=1);

namespace Core;

use PDO;

abstract class BaseController
{
    private bool $sqliteImmediateTransaction = false;
    protected function now(): string
    {
        return gmdate('Y-m-d H:i:s');
    }

    protected function uuid(): string
    {
        $bytes = random_bytes(16);
        $bytes[6] = chr((ord($bytes[6]) & 0x0f) | 0x40);
        $bytes[8] = chr((ord($bytes[8]) & 0x3f) | 0x80);
        return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($bytes), 4));
    }

    protected function companyId(array $input): string
    {
        return (string)($input['companyId'] ?? Config::get('app.default_company_id', 'company1'));
    }

    protected function idempotencyKey(): ?string
    {
        return Request::header('Idempotency-Key') ?? Request::header('X-Idempotency-Key');
    }

    protected function clientId(): string
    {
        return trim(Request::header('X-Client-Id') ?? '');
    }

    protected function requestFingerprint(array $values): string
    {
        ksort($values);
        return hash('sha256', json_encode($values, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_THROW_ON_ERROR));
    }

    protected function isUniqueConstraintViolation(\Throwable $error): bool
    {
        for ($current = $error; $current !== null; $current = $current->getPrevious()) {
            $code = (string)$current->getCode();
            $message = strtolower($current->getMessage());
            if (in_array($code, ['23000', '23505', '19'], true)
                || str_contains($message, 'unique constraint')
                || str_contains($message, 'duplicate entry')) {
                return true;
            }
        }
        return false;
    }

    protected function db()
    {
        return Ar::connection();
    }

    protected function pdo(): PDO
    {
        return $this->db()->connection;
    }

    protected function one(string $sql, array $params = []): ?array
    {
        $stmt = $this->pdo()->prepare($sql);
        $stmt->execute($params);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return $row === false ? null : $row;
    }

    protected function many(string $sql, array $params = []): array
    {
        $stmt = $this->pdo()->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    protected function beginWriteTransaction(): void
    {
        if ($this->pdo()->getAttribute(PDO::ATTR_DRIVER_NAME) === 'sqlite') {
            $this->pdo()->exec('pragma busy_timeout = 5000');
            $this->pdo()->exec('begin immediate');
            $this->sqliteImmediateTransaction = true;
            return;
        }
        $this->db()->transaction();
    }

    protected function lockRow(string $table, string $id): ?array
    {
        $allowed = ['fund_assistant_accounts', 'bazars', 'money_return_requests', 'ledger_entries'];
        if (!in_array($table, $allowed, true)) {
            throw new \InvalidArgumentException('Unsupported lock table');
        }
        $suffix = $this->pdo()->getAttribute(PDO::ATTR_DRIVER_NAME) === 'mysql'
            ? ' for update'
            : '';
        return $this->one("select * from {$table} where id = :id{$suffix}", ['id' => $id]);
    }

    /**
     * Appends one immutable balance change and updates its account atomically.
     * The caller must already hold the account row lock within a write transaction.
     *
     * @param array<string, mixed> $account
     * @param array<string, mixed> $entry
     * @return array{ledger: array<string, mixed>, balance: float}
     */
    protected function appendBalanceChange(array $account, array $entry): array
    {
        $before = round((float)$account['current_balance'], 2);
        $signedAmount = round((float)$entry['signed_amount'], 2);
        $after = round($before + $signedAmount, 2);
        $now = $entry['created_at'] ?? $this->now();
        $sequenceRow = $this->one(
            'select coalesce(max(ledger_sequence), 0) as max_sequence from ledger_entries where account_id = :account_id',
            ['account_id' => $account['id']]
        );
        $ledger = Ar::create('LedgerEntry', $entry + [
            'ledger_sequence' => (int)$sequenceRow['max_sequence'] + 1,
            'id' => $this->uuid(),
            'company_id' => $account['company_id'],
            'fund_id' => $account['fund_id'],
            'account_id' => $account['id'],
            'balance_before' => $before,
            'balance_after' => $after,
            'created_at' => $now,
        ]);
        Ar::update('FundAssistantAccount', (string)$account['id'], [
            'current_balance' => $after,
            'updated_at' => $now,
        ]);
        return ['ledger' => $ledger, 'balance' => $after];
    }

    protected function commitWriteTransaction(): void
    {
        if ($this->sqliteImmediateTransaction) {
            $this->pdo()->exec('commit');
            $this->sqliteImmediateTransaction = false;
            return;
        }
        $this->db()->commit();
    }

    protected function rollbackWriteTransaction(): void
    {
        try {
            if ($this->sqliteImmediateTransaction) {
                $this->pdo()->exec('rollback');
                $this->sqliteImmediateTransaction = false;
                return;
            }
            $this->db()->rollback();
        } catch (\Throwable) {
            $this->sqliteImmediateTransaction = false;
            // Preserve the original operation error when the transaction already ended.
        }
    }
}
