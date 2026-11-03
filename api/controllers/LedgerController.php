<?php

declare(strict_types=1);

namespace Controllers;

use Core\Ar;
use Core\BaseController;

final class LedgerController extends BaseController
{
    public function list(array $input): array
    {
        return Ar::all('LedgerEntry', [
            'company_id' => $this->companyId($input),
            'fund_id' => $input['fundId'] ?? null,
            'account_id' => $input['accountId'] ?? null,
            'type' => $input['type'] ?? null,
        ], (int)($input['limit'] ?? 100));
    }

    public function reverse(array $input): array
    {
        $idempotencyKey = $this->idempotencyKey();
        $clientId = $this->clientId();
        if ($idempotencyKey === null || trim($idempotencyKey) === '' || $clientId === '') {
            \Core\Response::error('Idempotency-Key and X-Client-Id headers are required', 422);
        }
        $fingerprint = null;
        $this->beginWriteTransaction();
        try {
            $original = $this->lockRow('ledger_entries', (string)$input['originalLedgerEntryId']);
            if ($original === null) {
                \Core\Response::error('Ledger entry not found', 404);
            }
            if ((string)$original['company_id'] !== $this->companyId($input) || $original['reverses_ledger_entry_id'] !== null) {
                \Core\Response::error('Ledger entry cannot be reversed', 409);
            }
            $fingerprint = $this->requestFingerprint(['original_ledger_entry_id' => $original['id'], 'reason' => $input['reason']]);
            $existing = $this->one(
                'select * from ledger_entries where company_id = :company_id and created_by = :created_by and client_id = :client_id and idempotency_key = :idempotency_key',
                ['company_id' => $original['company_id'], 'created_by' => $input['createdBy'], 'client_id' => $clientId, 'idempotency_key' => $idempotencyKey]
            );
            if ($existing !== null) {
                if (!hash_equals((string)$existing['request_fingerprint'], $fingerprint)) {
                    \Core\Response::error('Idempotency key was already used with a different request', 409);
                }
                $this->commitWriteTransaction();
                return ['ledgerEntry' => $existing, 'accountBalance' => (float)$existing['balance_after'], 'idempotentReplay' => true];
            }
            if ($this->one('select id from ledger_entries where reverses_ledger_entry_id = :id', ['id' => $original['id']]) !== null) {
                \Core\Response::error('Ledger entry was already reversed', 409);
            }
            $account = $this->lockRow('fund_assistant_accounts', (string)$original['account_id']);
            if ($account === null) {
                \Core\Response::error('Account not found', 404);
            }
            $now = $this->now();
            $posted = $this->appendBalanceChange($account, [
                'type' => 'adjustment',
                'amount' => (float)$original['amount'],
                'signed_amount' => -(float)$original['signed_amount'],
                'source_type' => 'ledger_reversal',
                'source_id' => $original['id'],
                'reverses_ledger_entry_id' => $original['id'],
                'created_by' => $input['createdBy'],
                'note' => 'Reversal: ' . $input['reason'],
                'entry_date' => substr($now, 0, 10),
                'created_at' => $now,
                'idempotency_key' => $idempotencyKey,
                'client_id' => $clientId,
                'request_fingerprint' => $fingerprint,
            ]);
            $this->commitWriteTransaction();
            return ['ledgerEntry' => $posted['ledger'], 'accountBalance' => $posted['balance']];
        } catch (\Throwable $error) {
            $this->rollbackWriteTransaction();
            if ($this->isUniqueConstraintViolation($error)) {
                $existing = $this->one(
                    'select * from ledger_entries where company_id = :company_id and created_by = :created_by and client_id = :client_id and idempotency_key = :idempotency_key',
                    ['company_id' => $this->companyId($input), 'created_by' => $input['createdBy'], 'client_id' => $clientId, 'idempotency_key' => $idempotencyKey]
                );
                if ($existing !== null) {
                    if (!is_string($fingerprint) || !hash_equals((string)$existing['request_fingerprint'], $fingerprint)) {
                        \Core\Response::error('Idempotency key was already used with a different request', 409);
                    }
                    return ['ledgerEntry' => $existing, 'accountBalance' => (float)$existing['balance_after'], 'idempotentReplay' => true];
                }
            }
            throw $error;
        }
    }

    public function reconcile(array $input): array
    {
        $params = ['company_id' => $this->companyId($input)];
        $accountFilter = '';
        if (!empty($input['accountId'])) {
            $accountFilter = ' and a.id = :account_id';
            $params['account_id'] = $input['accountId'];
        }
        $rows = $this->many(
            "select a.id as account_id, a.current_balance,
                    coalesce(sum(case when l.voided_at is null then l.signed_amount else 0 end), 0) as ledger_balance
             from fund_assistant_accounts a
             left join ledger_entries l on l.account_id = a.id
             where a.company_id = :company_id{$accountFilter}
             group by a.id, a.current_balance
             order by a.id",
            $params
        );
        $mismatches = [];
        foreach ($rows as $row) {
            $accountMismatches = [];
            if (abs((float)$row['current_balance'] - (float)$row['ledger_balance']) >= 0.005) {
                $accountMismatches[] = [
                    'reason' => 'stored_balance_differs_from_ledger_sum',
                    'expected' => (float)$row['ledger_balance'],
                    'actual' => (float)$row['current_balance'],
                ];
            }
            $entries = $this->many(
                'select id, signed_amount, balance_before, balance_after, ledger_sequence from ledger_entries
                 where account_id = :account_id order by ledger_sequence',
                ['account_id' => $row['account_id']]
            );
            $previousAfter = null;
            foreach ($entries as $entry) {
                if ($entry['balance_before'] === null || $entry['balance_after'] === null || $entry['ledger_sequence'] === null) {
                    $accountMismatches[] = ['ledgerEntryId' => $entry['id'], 'reason' => 'missing_audit_snapshot'];
                    break;
                }
                $before = (float)$entry['balance_before'];
                $after = (float)$entry['balance_after'];
                $expectedAfter = round($before + (float)$entry['signed_amount'], 2);
                if (abs($after - $expectedAfter) >= 0.005) {
                    $accountMismatches[] = ['ledgerEntryId' => $entry['id'], 'reason' => 'snapshot_arithmetic_mismatch'];
                    break;
                }
                if ($previousAfter !== null && abs($before - $previousAfter) >= 0.005) {
                    $accountMismatches[] = ['ledgerEntryId' => $entry['id'], 'reason' => 'snapshot_chain_break'];
                    break;
                }
                $previousAfter = $after;
            }
            if ($accountMismatches !== []) {
                $mismatches[] = $row + ['auditMismatches' => $accountMismatches];
            }
        }
        return ['accounts' => $rows, 'mismatches' => $mismatches, 'consistent' => $mismatches === []];
    }
}
