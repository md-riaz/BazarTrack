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
        $mismatches = array_values(array_filter($rows, static function (array $row): bool {
            return abs((float)$row['current_balance'] - (float)$row['ledger_balance']) >= 0.005;
        }));
        return ['accounts' => $rows, 'mismatches' => $mismatches, 'consistent' => $mismatches === []];
    }
}
