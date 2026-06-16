<?php

declare(strict_types=1);

namespace Controllers;

use Core\Ar;
use Core\BaseController;
use Core\Request;
use Core\Response;

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
        $account = $this->account((string)$input['accountId']);
        $amount = round((float)$input['amount'], 2);
        if ($amount <= 0) {
            Response::error('Amount must be greater than zero', 422);
        }

        $idempotencyKey = $this->idempotencyKey();
        if ($idempotencyKey !== null) {
            $existing = Ar::first('MoneyReturnRequest', [
                'company_id' => $account['company_id'],
                'idempotency_key' => $idempotencyKey,
            ]);
            if ($existing !== null) {
                return ['request' => $existing, 'idempotentReplay' => true];
            }
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
        ]);

        return ['request' => $request];
    }

    public function confirm(array $input): array
    {
        Request::require($input, ['id', 'confirmedBy']);
        $request = $this->request((string)$input['id']);
        if ($request['status'] === 'confirmed') {
            return [
                'request' => $request,
                'ledgerEntry' => $request['ledger_entry_id'] ? Ar::find('LedgerEntry', (string)$request['ledger_entry_id']) : null,
                'idempotentReplay' => true,
            ];
        }
        if ($request['status'] !== 'pending') {
            Response::error('Only pending return requests can be confirmed', 409);
        }

        $amount = (float)$request['amount'];
        $now = $this->now();
        $ledgerId = $this->uuid();
        $connection = $this->db();

        $connection->transaction();
        try {
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
                'received_by' => $input['receivedBy'] ?? $input['confirmedBy'],
                'note' => $input['note'] ?? $request['note'],
                'entry_date' => $input['entryDate'] ?? substr($now, 0, 10),
                'created_at' => $now,
            ]);
            $updatedRequest = Ar::update('MoneyReturnRequest', $request['id'], [
                'status' => 'confirmed',
                'confirmed_by' => $input['confirmedBy'],
                'confirmed_at' => $now,
                'ledger_entry_id' => $ledgerId,
            ]);
            $accountBefore = $this->account($request['account_id']);
            Ar::update('FundAssistantAccount', $request['account_id'], [
                'current_balance' => (float)$accountBefore['current_balance'] - $amount,
                'updated_at' => $now,
            ]);
            $account = $this->account($request['account_id']);
            $connection->commit();
        } catch (\Throwable $e) {
            $connection->rollback();
            throw $e;
        }

        return ['request' => $updatedRequest, 'ledgerEntry' => $ledger, 'accountBalance' => (float)$account['current_balance']];
    }

    public function reject(array $input): array
    {
        Request::require($input, ['id', 'rejectedBy']);
        $request = $this->request((string)$input['id']);
        if ($request['status'] !== 'pending') {
            Response::error('Only pending return requests can be rejected', 409);
        }
        return ['request' => Ar::update('MoneyReturnRequest', $request['id'], [
            'status' => 'rejected',
            'rejected_by' => $input['rejectedBy'],
            'rejected_at' => $this->now(),
            'rejection_reason' => $input['reason'] ?? null,
        ])];
    }

    private function request(string $id): array
    {
        $request = Ar::find('MoneyReturnRequest', $id);
        if ($request === null) {
            Response::error('Return request not found', 404);
        }
        return $request;
    }

    private function account(string $id): array
    {
        $account = Ar::find('FundAssistantAccount', $id);
        if ($account === null) {
            Response::error('Account not found', 404);
        }
        return $account;
    }
}
