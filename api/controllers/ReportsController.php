<?php

declare(strict_types=1);

namespace Controllers;

use Core\BaseController;
use Core\Request;

final class ReportsController extends BaseController
{
    public function summary(array $input): array
    {
        Request::require($input, ['from', 'to']);
        $companyId = $this->companyId($input);
        $params = ['company_id' => $companyId, 'from' => $input['from'], 'to' => $input['to']];
        $filter = '';
        if (!empty($input['fundId'])) {
            $filter .= ' and fund_id = :fund_id';
            $params['fund_id'] = $input['fundId'];
        }
        if (!empty($input['accountId'])) {
            $filter .= ' and account_id = :account_id';
            $params['account_id'] = $input['accountId'];
        }

        $rows = $this->many(
            "select type, sum(amount) as amount, sum(signed_amount) as signed_amount
             from ledger_entries
             where company_id = :company_id and entry_date >= :from and entry_date <= :to{$filter}
             group by type",
            $params
        );

        $summary = [
            'fundGiven' => 0.0,
            'returnedConfirmed' => 0.0,
            'bazarSpent' => 0.0,
            'adjustments' => 0.0,
            'netBalanceChange' => 0.0,
        ];
        foreach ($rows as $row) {
            $amount = (float)$row['amount'];
            $signed = (float)$row['signed_amount'];
            $summary['netBalanceChange'] += $signed;
            match ($row['type']) {
                'fund_gave_money' => $summary['fundGiven'] += $amount,
                'assistant_return_confirmed' => $summary['returnedConfirmed'] += $amount,
                'bazar_spend' => $summary['bazarSpent'] += $amount,
                'adjustment' => $summary['adjustments'] += $signed,
                default => null,
            };
        }

        return ['from' => $input['from'], 'to' => $input['to'], 'summary' => $summary, 'breakdown' => $rows];
    }
}
