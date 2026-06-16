<?php

declare(strict_types=1);

namespace Controllers;

use Core\Ar;
use Core\BaseController;
use Core\Request;
use Core\Response;

final class AccountsController extends BaseController
{
    public function list(array $input): array
    {
        return Ar::all('FundAssistantAccount', [
            'company_id' => $this->companyId($input),
            'fund_id' => $input['fundId'] ?? null,
            'assistant_id' => $input['assistantId'] ?? null,
            'status' => $input['status'] ?? 'active',
        ]);
    }

    public function show(array $input): array
    {
        Request::require($input, ['id']);
        $account = Ar::find('FundAssistantAccount', (string)$input['id']);
        if ($account === null) {
            Response::error('Account not found', 404);
        }
        return $account;
    }

    public function create(array $input): array
    {
        Request::require($input, ['fundId', 'assistantId']);
        $now = $this->now();
        return Ar::create('FundAssistantAccount', [
            'id' => $input['id'] ?? $this->uuid(),
            'company_id' => $this->companyId($input),
            'fund_id' => $input['fundId'],
            'assistant_id' => $input['assistantId'],
            'status' => 'active',
            'current_balance' => 0,
            'created_at' => $now,
            'updated_at' => $now,
        ]);
    }
}
