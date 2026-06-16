<?php

declare(strict_types=1);

namespace Controllers;

use Core\Ar;
use Core\BaseController;
use Core\Request;
use Core\Response;

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
        $account = $this->account((string)$input['accountId']);
        $amount = round((float)$input['amount'], 2);
        if ($amount <= 0) {
            Response::error('Amount must be greater than zero', 422);
        }

        $idempotencyKey = $this->idempotencyKey();
        if ($idempotencyKey !== null) {
            $existing = Ar::first('MoneyEntry', [
                'company_id' => $account['company_id'],
                'idempotency_key' => $idempotencyKey,
            ]);
            if ($existing !== null) {
                return ['entry' => $existing, 'idempotentReplay' => true];
            }
        }

        $now = $this->now();
        $entryId = $input['id'] ?? $this->uuid();
        $ledgerId = $this->uuid();
        $connection = $this->db();

        $connection->transaction();
        try {
            $entry = Ar::create('MoneyEntry', [
                'id' => $entryId,
                'company_id' => $account['company_id'],
                'fund_id' => $account['fund_id'],
                'account_id' => $account['id'],
                'type' => 'fund_gave_money',
                'amount' => $amount,
                'signed_amount' => $amount,
                'note' => $input['note'] ?? null,
                'entry_date' => $input['entryDate'] ?? substr($now, 0, 10),
                'created_by' => $input['createdBy'],
                'created_at' => $now,
                'updated_at' => $now,
                'idempotency_key' => $idempotencyKey,
            ]);

            Ar::create('LedgerEntry', [
                'id' => $ledgerId,
                'company_id' => $account['company_id'],
                'fund_id' => $account['fund_id'],
                'account_id' => $account['id'],
                'type' => 'fund_gave_money',
                'amount' => $amount,
                'signed_amount' => $amount,
                'source_type' => 'money_entry',
                'source_id' => $entryId,
                'created_by' => $input['createdBy'],
                'paid_by' => $input['paidBy'] ?? $input['createdBy'],
                'paid_to' => $account['assistant_id'],
                'note' => $input['note'] ?? null,
                'entry_date' => $input['entryDate'] ?? substr($now, 0, 10),
                'created_at' => $now,
            ]);

            $updatedBalance = (float)$account['current_balance'] + $amount;
            Ar::update('FundAssistantAccount', $account['id'], [
                'current_balance' => $updatedBalance,
                'updated_at' => $now,
            ]);
            $updatedAccount = $this->account($account['id']);
            $connection->commit();
        } catch (\Throwable $e) {
            $connection->rollback();
            throw $e;
        }

        return ['entry' => $entry, 'accountBalance' => (float)$updatedAccount['current_balance']];
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
