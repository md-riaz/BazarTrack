<?php

declare(strict_types=1);

namespace Core;

final class Authorizer
{
    public static function authorizeObject(string $cmd, string $action, array &$input, Principal $principal): void
    {
        $cmd = strtolower($cmd);
        self::assertInputCompanyObjects($cmd, $input, $principal);
        self::assertExactResourceScope($cmd, $action, $input, $principal);

        if (isset($input['fundId']) && !self::canAccessFund((string)$input['fundId'], $principal)) {
            Response::error('Forbidden', 403);
        }
        if (isset($input['accountId']) && !self::canAccessAccount((string)$input['accountId'], $principal)) {
            Response::error('Forbidden', 403);
        }

        self::enforceManagerCapability($cmd, $action, $input, $principal);
        self::validateParticipants($cmd, $action, $input, $principal);

        if ($cmd === 'funds' && $action === 'show') {
            self::requireFund((string)($input['id'] ?? ''), $principal);
        } elseif ($cmd === 'accounts' && $action === 'show') {
            self::requireAccount((string)($input['id'] ?? ''), $principal);
        } elseif ($cmd === 'bazars' && in_array($action, ['show', 'close'], true)) {
            self::requireBazar((string)($input['id'] ?? ''), $principal);
        } elseif ($cmd === 'bazars' && in_array($action, ['addItem'], true)) {
            self::requireBazar((string)($input['bazarId'] ?? ''), $principal);
        } elseif ($cmd === 'bazars' && in_array($action, ['updateItem', 'uploadReceipt', 'receipt'], true)) {
            $item = self::requireBazarItem((string)($input['id'] ?? ''), $principal);
            if (in_array($action, ['updateItem', 'uploadReceipt'], true)) {
                $bazar = Ar::find('Bazar', (string)$item['bazar_id']);
                if ($bazar === null || (string)$bazar['status'] === 'closed') {
                    Response::error('Closed bazar items cannot be changed', 409);
                }
            }
        } elseif ($cmd === 'returns' && in_array($action, ['confirm', 'reject'], true)) {
            self::requireReturnRequest((string)($input['id'] ?? ''), $principal);
        }

        if ($principal->isAssistant()) {
            if ($cmd === 'returns' && $action === 'create') {
                $account = self::requireAccount((string)($input['accountId'] ?? ''), $principal);
                if ((string)$account['assistant_id'] !== $principal->userId) {
                    Response::error('Forbidden', 403);
                }
            }
            if ($cmd === 'bazars' && $action === 'create') {
                self::requireFund((string)($input['fundId'] ?? ''), $principal);
                if (!empty($input['assignedTo']) && (string)$input['assignedTo'] !== $principal->userId) {
                    Response::error('Assistants cannot assign bazars', 403);
                }
                $input['assignedTo'] = null;
            }
        }

        if ($principal->isManager() && $cmd === 'reports' && $action === 'summary' && empty($input['fundId'])) {
            $fundIds = self::accessibleFundIds($principal);
            if (count($fundIds) !== 1) {
                Response::error('fundId is required for scoped reports', 422);
            }
            $input['fundId'] = $fundIds[0];
        }
        if ($principal->isManager() && $cmd === 'ledger' && $action === 'reconcile' && empty($input['accountId'])) {
            Response::error('accountId is required for scoped reconciliation', 422);
        }
    }

    public static function filterResult(string $cmd, string $action, mixed $result, ?Principal $principal): mixed
    {
        if ($principal === null || $principal->isAdmin() || $action !== 'list' || !is_array($result)) {
            return $result;
        }

        $fundIds = array_flip(self::accessibleFundIds($principal));
        return array_values(array_filter($result, static function ($row) use ($cmd, $principal, $fundIds): bool {
            if (!is_array($row) || (isset($row['company_id']) && (string)$row['company_id'] !== $principal->companyId)) {
                return false;
            }
            return match (strtolower($cmd)) {
                'funds' => isset($fundIds[(string)($row['id'] ?? '')]),
                'accounts' => isset($fundIds[(string)($row['fund_id'] ?? '')]) && (!$principal->isAssistant() || (string)($row['assistant_id'] ?? '') === $principal->userId),
                'bazars' => isset($fundIds[(string)($row['fund_id'] ?? '')]) && (!$principal->isAssistant() || $row['assigned_to'] === null || (string)$row['assigned_to'] === $principal->userId),
                'returns' => isset($fundIds[(string)($row['fund_id'] ?? '')]) && (!$principal->isAssistant() || (string)($row['assistant_id'] ?? '') === $principal->userId),
                'money', 'ledger' => isset($fundIds[(string)($row['fund_id'] ?? '')]),
                default => true,
            };
        }));
    }

    private static function validateParticipants(string $cmd, string $action, array $input, Principal $principal): void
    {
        $rules = [];
        if ($cmd === 'bazars' && $action === 'create' && !empty($input['assignedTo'])) {
            $rules[(string)$input['assignedTo']] = ['assistant'];
        }
        if ($cmd === 'accounts' && $action === 'create' && !empty($input['assistantId'])) {
            $rules[(string)$input['assistantId']] = ['assistant'];
        }
        if ($cmd === 'funds' && $action === 'addManager' && !empty($input['userId'])) {
            $rules[(string)$input['userId']] = ['owner'];
        }
        foreach ($rules as $userId => $roles) {
            $user = Ar::find('User', $userId);
            if ($user === null || (string)$user['company_id'] !== $principal->companyId || (int)($user['is_active'] ?? 0) !== 1 || !in_array((string)$user['role'], $roles, true)) {
                Response::error('Invalid participant', 422);
            }
        }

        if ($cmd === 'returns' && $action === 'create' && !empty($input['expectedReceiverId'])) {
            $receiver = Ar::find('User', (string)$input['expectedReceiverId']);
            $account = isset($input['accountId']) ? Ar::find('FundAssistantAccount', (string)$input['accountId']) : null;
            if ($receiver === null || $account === null || (string)$receiver['company_id'] !== $principal->companyId || (int)($receiver['is_active'] ?? 0) !== 1 || !in_array((string)$receiver['role'], ['admin', 'owner'], true)) {
                Response::error('Invalid expected receiver', 422);
            }
            if ((string)$receiver['role'] === 'owner' && Ar::first('FundManager', [
                'company_id' => $principal->companyId,
                'fund_id' => $account['fund_id'],
                'user_id' => $receiver['id'],
                'can_confirm_return' => 1,
            ]) === null) {
                Response::error('Invalid expected receiver', 422);
            }
        }
    }

    private static function enforceManagerCapability(string $cmd, string $action, array $input, Principal $principal): void
    {
        if (!$principal->isManager()) {
            return;
        }
        $capability = match ($cmd . '.' . $action) {
            'money.give' => 'can_give_money',
            'returns.confirm', 'returns.reject' => 'can_confirm_return',
            'reports.summary' => 'can_view_reports',
            default => null,
        };
        if ($capability === null) {
            return;
        }

        $fundId = isset($input['fundId']) ? (string)$input['fundId'] : null;
        if ($fundId === null && isset($input['accountId'])) {
            $account = Ar::find('FundAssistantAccount', (string)$input['accountId']);
            $fundId = $account === null ? null : (string)$account['fund_id'];
        }
        if ($fundId === null && $cmd === 'returns' && isset($input['id'])) {
            $request = Ar::find('MoneyReturnRequest', (string)$input['id']);
            $fundId = $request === null ? null : (string)$request['fund_id'];
        }
        if ($fundId === null && $cmd === 'reports') {
            $fundIds = self::accessibleFundIds($principal);
            if (count($fundIds) === 1) {
                $fundId = $fundIds[0];
                $input['fundId'] = $fundId;
            }
        }
        if ($fundId === null) {
            Response::error('fundId or accountId is required', 422);
        }

        $membership = Ar::first('FundManager', [
            'company_id' => $principal->companyId,
            'fund_id' => $fundId,
            'user_id' => $principal->userId,
        ]);
        if ($membership === null || (int)($membership[$capability] ?? 0) !== 1) {
            Response::error('Forbidden', 403);
        }
    }

    public static function accessibleFundIds(Principal $principal): array
    {
        if ($principal->isAdmin()) {
            return array_column(Ar::all('Fund', ['company_id' => $principal->companyId], 500), 'id');
        }
        if ($principal->isManager()) {
            return array_values(array_unique(array_column(Ar::all('FundManager', [
                'company_id' => $principal->companyId,
                'user_id' => $principal->userId,
            ], 500), 'fund_id')));
        }
        return array_values(array_unique(array_column(Ar::all('FundAssistantAccount', [
            'company_id' => $principal->companyId,
            'assistant_id' => $principal->userId,
            'status' => 'active',
        ], 500), 'fund_id')));
    }

    private static function canAccessFund(string $fundId, Principal $principal): bool
    {
        $fund = Ar::find('Fund', $fundId);
        return $fund !== null
            && (string)$fund['company_id'] === $principal->companyId
            && in_array($fundId, self::accessibleFundIds($principal), true);
    }

    private static function canAccessAccount(string $accountId, Principal $principal): bool
    {
        $account = Ar::find('FundAssistantAccount', $accountId);
        if ($account === null || (string)$account['company_id'] !== $principal->companyId) {
            return false;
        }
        if ($principal->isAssistant()) {
            return (string)$account['assistant_id'] === $principal->userId;
        }
        return in_array((string)$account['fund_id'], self::accessibleFundIds($principal), true);
    }

    private static function requireFund(string $fundId, Principal $principal): array
    {
        if ($fundId === '' || !self::canAccessFund($fundId, $principal)) {
            Response::error('Resource not found', 404);
        }
        return Ar::find('Fund', $fundId);
    }

    private static function requireAccount(string $accountId, Principal $principal): array
    {
        if ($accountId === '' || !self::canAccessAccount($accountId, $principal)) {
            Response::error('Resource not found', 404);
        }
        return Ar::find('FundAssistantAccount', $accountId);
    }

    private static function requireBazar(string $id, Principal $principal): array
    {
        $bazar = Ar::find('Bazar', $id);
        if ($bazar === null || (string)$bazar['company_id'] !== $principal->companyId || !self::canAccessFund((string)$bazar['fund_id'], $principal)) {
            Response::error('Resource not found', 404);
        }
        if ($principal->isAssistant() && $bazar['assigned_to'] !== null && (string)$bazar['assigned_to'] !== $principal->userId) {
            Response::error('Resource not found', 404);
        }
        return $bazar;
    }

    private static function requireBazarItem(string $id, Principal $principal): array
    {
        $item = Ar::find('BazarItem', $id);
        if ($item === null) {
            Response::error('Resource not found', 404);
        }
        self::requireBazar((string)$item['bazar_id'], $principal);
        return $item;
    }

    private static function requireReturnRequest(string $id, Principal $principal): array
    {
        $request = Ar::find('MoneyReturnRequest', $id);
        if ($request === null || (string)$request['company_id'] !== $principal->companyId || !self::canAccessFund((string)$request['fund_id'], $principal)) {
            Response::error('Resource not found', 404);
        }
        return $request;
    }

    private static function assertExactResourceScope(string $cmd, string $action, array $input, Principal $principal): void
    {
        $id = (string)($input['id'] ?? '');
        if ($id === '') {
            return;
        }
        $record = match ($cmd) {
            'funds' => Ar::find('Fund', $id),
            'accounts' => Ar::find('FundAssistantAccount', $id),
            'bazars' => Ar::find('Bazar', $id),
            'returns' => Ar::find('MoneyReturnRequest', $id),
            'users' => Ar::find('User', $id),
            default => null,
        };
        if ($record !== null && isset($record['company_id']) && (string)$record['company_id'] !== $principal->companyId) {
            Response::error('Resource not found', 404);
        }
    }

    private static function assertInputCompanyObjects(string $cmd, array $input, Principal $principal): void
    {
        if (isset($input['fundId'])) {
            $fund = Ar::find('Fund', (string)$input['fundId']);
            if ($fund === null || (string)$fund['company_id'] !== $principal->companyId) {
                Response::error('Resource not found', 404);
            }
        }
        if (isset($input['accountId'])) {
            $account = Ar::find('FundAssistantAccount', (string)$input['accountId']);
            if ($account === null || (string)$account['company_id'] !== $principal->companyId) {
                Response::error('Resource not found', 404);
            }
        }
    }
}
