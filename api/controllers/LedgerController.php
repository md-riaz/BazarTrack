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
}
