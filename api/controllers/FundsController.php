<?php

declare(strict_types=1);

namespace Controllers;

use Core\Ar;
use Core\BaseController;
use Core\Request;
use Core\Response;

final class FundsController extends BaseController
{
    public function list(array $input): array
    {
        return Ar::all('Fund', [
            'company_id' => $this->companyId($input),
            'status' => $input['status'] ?? 'active',
        ]);
    }

    public function show(array $input): array
    {
        Request::require($input, ['id']);
        $fund = Ar::find('Fund', (string)$input['id']);
        if ($fund === null) {
            Response::error('Fund not found', 404);
        }
        return $fund;
    }

    public function create(array $input): array
    {
        Request::require($input, ['name', 'createdBy']);
        $now = $this->now();
        return Ar::create('Fund', [
            'id' => $input['id'] ?? $this->uuid(),
            'company_id' => $this->companyId($input),
            'name' => $input['name'],
            'type' => $input['type'] ?? 'office_bazar',
            'status' => 'active',
            'created_by' => $input['createdBy'],
            'created_at' => $now,
            'updated_at' => $now,
        ]);
    }

    public function addManager(array $input): array
    {
        Request::require($input, ['fundId', 'userId']);
        $now = $this->now();
        return Ar::create('FundManager', [
            'id' => $input['id'] ?? $this->uuid(),
            'company_id' => $this->companyId($input),
            'fund_id' => $input['fundId'],
            'user_id' => $input['userId'],
            'can_give_money' => (int)($input['canGiveMoney'] ?? 1),
            'can_confirm_return' => (int)($input['canConfirmReturn'] ?? 1),
            'can_view_reports' => (int)($input['canViewReports'] ?? 1),
            'created_at' => $now,
        ]);
    }
}
