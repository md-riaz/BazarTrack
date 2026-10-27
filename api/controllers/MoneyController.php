<?php

declare(strict_types=1);

namespace Controllers;

use Core\Ar;
use Core\BaseController;
use Core\Request;
use Core\Response;
use Throwable;

final class MoneyController extends BaseController
{
    public function list(array $input): array
    {
        return Ar::all('MoneyEntry', [
            'company_id' => $this->companyId($input),
            'fund_id' => $input['fundId'] ?? null,
            'account_id' => $input['accountId'] ?? null,
            'type' => $input['type'] ?? null,
        ], (int)($input['limit'] ?? 100));
    }

    public function give(array $input): array
    {
        Request::require($input, ['accountId', 'amount', 'createdBy']);
        $amount = round((float)$input['amount'], 2);
        if ($amount <= 0) {
            Response::error('Amount must be greater than zero', 422);
        }
        $idempotencyKey = $this->idempotencyKey();
        $clientId = $this->clientId();
        if ($idempotencyKey === null || trim($idempotencyKey) === '' || $clientId === '') {
            Response::error('Idempotency-Key and X-Client-Id headers are required', 422);
        }
        $entryDate = $input['entryDate'] ?? substr($this->now(), 0, 10);
        $fingerprint = $this->requestFingerprint([
            'account_id' => (string)$input['accountId'],
            'amount' => number_format($amount, 2, '.', ''),
            'entry_date' => $entryDate,
            'note' => $input['note'] ?? null,
        ]);

        $this->beginWriteTransaction();
        try {
            $account = $this->lockRow('fund_assistant_accounts', (string)$input['accountId']);
            if ($account === null) {
                Response::error('Account not found', 404);
            }
            $existing = $this->one(
                'select * from money_entries where company_id = :company_id and created_by = :created_by and client_id = :client_id and idempotency_key = :idempotency_key',
                [
                    'company_id' => $account['company_id'],
                    'created_by' => $input['createdBy'],
                    'client_id' => $clientId,
                    'idempotency_key' => $idempotencyKey,
                ]
            );
            if ($existing !== null) {
                if (!hash_equals((string)$existing['request_fingerprint'], $fingerprint)) {
                    Response::error('Idempotency key was already used with a different request', 409);
                }
                $this->commitWriteTransaction();
                return [
                    'entry' => $existing,
                    'accountBalance' => (float)$account['current_balance'],
                    'idempotentReplay' => true,
                ];
            }

            $now = $this->now();
            $entryId = $input['id'] ?? $this->uuid();
            $entry = Ar::create('MoneyEntry', [
                'id' => $entryId,
                'company_id' => $account['company_id'],
                'fund_id' => $account['fund_id'],
                'account_id' => $account['id'],
                'type' => 'fund_gave_money',
                'amount' => $amount,
                'signed_amount' => $amount,
                'note' => $input['note'] ?? null,
                'entry_date' => $entryDate,
                'created_by' => $input['createdBy'],
                'created_at' => $now,
                'updated_at' => $now,
                'idempotency_key' => $idempotencyKey,
                'client_id' => $clientId,
                'request_fingerprint' => $fingerprint,
            ]);
            Ar::create('LedgerEntry', [
                'id' => $this->uuid(),
                'company_id' => $account['company_id'],
                'fund_id' => $account['fund_id'],
                'account_id' => $account['id'],
                'type' => 'fund_gave_money',
                'amount' => $amount,
                'signed_amount' => $amount,
                'source_type' => 'money_entry',
                'source_id' => $entryId,
                'created_by' => $input['createdBy'],
                'paid_by' => $input['createdBy'],
                'paid_to' => $account['assistant_id'],
                'note' => $input['note'] ?? null,
                'entry_date' => $entryDate,
                'created_at' => $now,
            ]);

            $balance = (float)$account['current_balance'] + $amount;
            Ar::update('FundAssistantAccount', (string)$account['id'], [
                'current_balance' => $balance,
                'updated_at' => $now,
            ]);
            $this->commitWriteTransaction();
            return ['entry' => $entry, 'accountBalance' => $balance];
        } catch (Throwable $error) {
            $this->rollbackWriteTransaction();
            if ($this->isUniqueConstraintViolation($error)) {
                $existing = $this->one(
                    'select * from money_entries where company_id = :company_id and created_by = :created_by and client_id = :client_id and idempotency_key = :idempotency_key',
                    [
                        'company_id' => $this->companyId($input),
                        'created_by' => $input['createdBy'],
                        'client_id' => $clientId,
                        'idempotency_key' => $idempotencyKey,
                    ]
                );
                if ($existing !== null) {
                    if (!hash_equals((string)$existing['request_fingerprint'], $fingerprint)) {
                        Response::error('Idempotency key was already used with a different request', 409);
                    }
                    $account = Ar::find('FundAssistantAccount', (string)$existing['account_id']);
                    return [
                        'entry' => $existing,
                        'accountBalance' => (float)($account['current_balance'] ?? 0),
                        'idempotentReplay' => true,
                    ];
                }
            }
            throw $error;
        }
    }
}
