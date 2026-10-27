<?php

declare(strict_types=1);

namespace Controllers;

use Core\Ar;
use Core\BaseController;
use Core\Request;
use Core\Response;
use Throwable;

final class ReturnsController extends BaseController
{
    public function list(array $input): array
    {
        return Ar::all('MoneyReturnRequest', [
            'company_id' => $this->companyId($input),
            'fund_id' => $input['fundId'] ?? null,
            'account_id' => $input['accountId'] ?? null,
            'assistant_id' => $input['assistantId'] ?? null,
            'status' => $input['status'] ?? null,
        ], (int)($input['limit'] ?? 100));
    }

    public function create(array $input): array
    {
        Request::require($input, ['accountId', 'amount', 'requestedBy']);
        $amount = round((float)$input['amount'], 2);
        if ($amount <= 0) {
            Response::error('Amount must be greater than zero', 422);
        }
        $idempotencyKey = $this->idempotencyKey();
        $clientId = $this->clientId();
        if ($idempotencyKey === null || trim($idempotencyKey) === '' || $clientId === '') {
            Response::error('Idempotency-Key and X-Client-Id headers are required', 422);
        }
        $fingerprint = $this->requestFingerprint([
            'account_id' => (string)$input['accountId'],
            'amount' => number_format($amount, 2, '.', ''),
            'expected_receiver_id' => $input['expectedReceiverId'] ?? null,
            'note' => $input['note'] ?? null,
        ]);

        $this->beginWriteTransaction();
        try {
            $account = $this->lockRow('fund_assistant_accounts', (string)$input['accountId']);
            if ($account === null) {
                Response::error('Account not found', 404);
            }
            $existing = $this->one(
                'select * from money_return_requests where company_id = :company_id and requested_by = :requested_by and client_id = :client_id and idempotency_key = :idempotency_key',
                [
                    'company_id' => $account['company_id'],
                    'requested_by' => $input['requestedBy'],
                    'client_id' => $clientId,
                    'idempotency_key' => $idempotencyKey,
                ]
            );
            if ($existing !== null) {
                if (!hash_equals((string)$existing['request_fingerprint'], $fingerprint)) {
                    Response::error('Idempotency key was already used with a different request', 409);
                }
                $this->commitWriteTransaction();
                return ['request' => $existing, 'idempotentReplay' => true];
            }
            if ($amount > (float)$account['current_balance']) {
                Response::error('Return amount exceeds current account balance', 422);
            }
            $request = Ar::create('MoneyReturnRequest', [
                'id' => $input['id'] ?? $this->uuid(),
                'company_id' => $account['company_id'],
                'fund_id' => $account['fund_id'],
                'account_id' => $account['id'],
                'assistant_id' => $account['assistant_id'],
                'amount' => $amount,
                'note' => $input['note'] ?? null,
                'requested_by' => $input['requestedBy'],
                'expected_receiver_id' => $input['expectedReceiverId'] ?? null,
                'status' => 'pending',
                'requested_at' => $this->now(),
                'idempotency_key' => $idempotencyKey,
                'client_id' => $clientId,
                'request_fingerprint' => $fingerprint,
            ]);
            $this->commitWriteTransaction();
            return ['request' => $request];
        } catch (Throwable $error) {
            $this->rollbackWriteTransaction();
            if ($this->isUniqueConstraintViolation($error)) {
                $existing = $this->one(
                    'select * from money_return_requests where company_id = :company_id and requested_by = :requested_by and client_id = :client_id and idempotency_key = :idempotency_key',
                    [
                        'company_id' => $this->companyId($input),
                        'requested_by' => $input['requestedBy'],
                        'client_id' => $clientId,
                        'idempotency_key' => $idempotencyKey,
                    ]
                );
                if ($existing !== null) {
                    if (!hash_equals((string)$existing['request_fingerprint'], $fingerprint)) {
                        Response::error('Idempotency key was already used with a different request', 409);
                    }
                    return ['request' => $existing, 'idempotentReplay' => true];
                }
            }
            throw $error;
        }
    }

    public function confirm(array $input): array
    {
        Request::require($input, ['id', 'confirmedBy']);
        $this->beginWriteTransaction();
        try {
            $request = $this->lockRow('money_return_requests', (string)$input['id']);
            if ($request === null) {
                Response::error('Return request not found', 404);
            }
            if ($request['status'] === 'confirmed') {
                $this->commitWriteTransaction();
                return [
                    'request' => $request,
                    'ledgerEntry' => $request['ledger_entry_id']
                        ? Ar::find('LedgerEntry', (string)$request['ledger_entry_id'])
                        : null,
                    'idempotentReplay' => true,
                ];
            }
            if ($request['status'] !== 'pending') {
                Response::error('Only pending return requests can be confirmed', 409);
            }
            if ($request['expected_receiver_id'] !== null
                && (string)$request['expected_receiver_id'] !== (string)$input['confirmedBy']) {
                Response::error('Return request must be confirmed by its expected receiver', 403);
            }

            $account = $this->lockRow('fund_assistant_accounts', (string)$request['account_id']);
            if ($account === null) {
                Response::error('Account not found', 404);
            }
            $amount = (float)$request['amount'];
            if ($amount > (float)$account['current_balance']) {
                Response::error('Return amount exceeds current account balance', 409);
            }

            $now = $this->now();
            $ledgerId = $this->uuid();
            $ledger = Ar::create('LedgerEntry', [
                'id' => $ledgerId,
                'company_id' => $request['company_id'],
                'fund_id' => $request['fund_id'],
                'account_id' => $request['account_id'],
                'type' => 'assistant_return_confirmed',
                'amount' => $amount,
                'signed_amount' => -$amount,
                'source_type' => 'return_request',
                'source_id' => $request['id'],
                'created_by' => $input['confirmedBy'],
                'returned_by' => $request['assistant_id'],
                'received_by' => $input['confirmedBy'],
                'note' => $input['note'] ?? $request['note'],
                'entry_date' => $input['entryDate'] ?? substr($now, 0, 10),
                'created_at' => $now,
            ]);
            $updatedRequest = Ar::update('MoneyReturnRequest', (string)$request['id'], [
                'status' => 'confirmed',
                'confirmed_by' => $input['confirmedBy'],
                'confirmed_at' => $now,
                'ledger_entry_id' => $ledgerId,
            ]);
            $balance = (float)$account['current_balance'] - $amount;
            Ar::update('FundAssistantAccount', (string)$account['id'], [
                'current_balance' => $balance,
                'updated_at' => $now,
            ]);
            $this->commitWriteTransaction();
            return ['request' => $updatedRequest, 'ledgerEntry' => $ledger, 'accountBalance' => $balance];
        } catch (Throwable $error) {
            $this->rollbackWriteTransaction();
            throw $error;
        }
    }

    public function reject(array $input): array
    {
        Request::require($input, ['id', 'rejectedBy']);
        $this->beginWriteTransaction();
        try {
            $request = $this->lockRow('money_return_requests', (string)$input['id']);
            if ($request === null) {
                Response::error('Return request not found', 404);
            }
            if ($request['status'] !== 'pending') {
                Response::error('Only pending return requests can be rejected', 409);
            }
            $updated = Ar::update('MoneyReturnRequest', (string)$request['id'], [
                'status' => 'rejected',
                'rejected_by' => $input['rejectedBy'],
                'rejected_at' => $this->now(),
                'rejection_reason' => $input['reason'] ?? null,
            ]);
            $this->commitWriteTransaction();
            return ['request' => $updated];
        } catch (Throwable $error) {
            $this->rollbackWriteTransaction();
            throw $error;
        }
    }
}
