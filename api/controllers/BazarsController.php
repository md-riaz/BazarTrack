<?php

declare(strict_types=1);

namespace Controllers;

use Core\Ar;
use Core\BaseController;
use Core\Request;
use Core\Response;

final class BazarsController extends BaseController
{
    public function list(array $input): array
    {
        return Ar::all('Bazar', [
            'company_id' => $this->companyId($input),
            'fund_id' => $input['fundId'] ?? null,
            'account_id' => $input['accountId'] ?? null,
            'assigned_to' => $input['assignedTo'] ?? null,
            'status' => $input['status'] ?? null,
        ], (int)($input['limit'] ?? 100));
    }

    public function show(array $input): array
    {
        Request::require($input, ['id']);
        $bazar = Ar::find('Bazar', (string)$input['id']);
        if ($bazar === null) {
            Response::error('Bazar not found', 404);
        }
        $items = Ar::all('BazarItem', ['bazar_id' => $bazar['id']], 500);
        return ['bazar' => $bazar, 'items' => $items];
    }

    public function create(array $input): array
    {
        Request::require($input, ['fundId', 'title', 'createdBy']);
        $now = $this->now();
        $bazar = Ar::create('Bazar', [
            'id' => $input['id'] ?? $this->uuid(),
            'company_id' => $this->companyId($input),
            'fund_id' => $input['fundId'],
            'account_id' => $input['accountId'] ?? null,
            'title' => $input['title'],
            'assigned_to' => $input['assignedTo'] ?? null,
            'bazar_date' => $input['bazarDate'] ?? substr($now, 0, 10),
            'status' => $input['status'] ?? 'draft',
            'created_by' => $input['createdBy'],
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        $items = [];
        foreach (($input['items'] ?? []) as $item) {
            $items[] = $this->addItemToBazar($bazar['id'], $item);
        }

        return ['bazar' => $bazar, 'items' => $items];
    }

    public function addItem(array $input): array
    {
        Request::require($input, ['bazarId', 'name']);
        return $this->addItemToBazar((string)$input['bazarId'], $input);
    }

    public function updateItem(array $input): array
    {
        Request::require($input, ['id']);
        $data = [];
        foreach (['name', 'quantity', 'price', 'status', 'note'] as $key) {
            if (array_key_exists($key, $input)) {
                $data[$key] = $input[$key];
            }
        }
        $data['updated_at'] = $this->now();
        return Ar::update('BazarItem', (string)$input['id'], $data);
    }

    public function close(array $input): array
    {
        Request::require($input, ['id', 'closedBy']);
        $bazar = Ar::find('Bazar', (string)$input['id']);
        if ($bazar === null) {
            Response::error('Bazar not found', 404);
        }
        if (!$bazar['account_id']) {
            Response::error('Bazar must have account_id before closing', 422);
        }

        $items = Ar::all('BazarItem', ['bazar_id' => $bazar['id'], 'status' => 'done'], 500);
        $total = array_reduce($items, static fn (float $sum, array $item): float => $sum + (float)($item['price'] ?? 0), 0.0);
        $now = $this->now();
        $connection = $this->db();

        $connection->transaction();
        try {
            $updated = Ar::update('Bazar', $bazar['id'], [
                'status' => 'closed',
                'closed_at' => $now,
                'updated_at' => $now,
            ]);
            if ($total > 0) {
                Ar::create('LedgerEntry', [
                    'id' => $this->uuid(),
                    'company_id' => $bazar['company_id'],
                    'fund_id' => $bazar['fund_id'],
                    'account_id' => $bazar['account_id'],
                    'type' => 'bazar_spend',
                    'amount' => $total,
                    'signed_amount' => -$total,
                    'source_type' => 'bazar',
                    'source_id' => $bazar['id'],
                    'created_by' => $input['closedBy'],
                    'note' => $input['note'] ?? null,
                    'entry_date' => substr($now, 0, 10),
                    'created_at' => $now,
                ]);
                $accountBefore = Ar::find('FundAssistantAccount', (string)$bazar['account_id']);
                Ar::update('FundAssistantAccount', (string)$bazar['account_id'], [
                    'current_balance' => (float)($accountBefore['current_balance'] ?? 0) - $total,
                    'updated_at' => $now,
                ]);
            }
            $account = Ar::find('FundAssistantAccount', (string)$bazar['account_id']);
            $connection->commit();
        } catch (\Throwable $e) {
            $connection->rollback();
            throw $e;
        }

        return ['bazar' => $updated, 'bazarSpent' => $total, 'accountBalance' => (float)($account['current_balance'] ?? 0)];
    }

    private function addItemToBazar(string $bazarId, array $item): array
    {
        $now = $this->now();
        return Ar::create('BazarItem', [
            'id' => $item['id'] ?? $this->uuid(),
            'bazar_id' => $bazarId,
            'name' => $item['name'],
            'quantity' => $item['quantity'] ?? null,
            'price' => $item['price'] ?? null,
            'status' => $item['status'] ?? 'pending',
            'note' => $item['note'] ?? null,
            'created_at' => $now,
            'updated_at' => $now,
        ]);
    }
}
