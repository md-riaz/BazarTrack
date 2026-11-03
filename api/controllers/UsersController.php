<?php

declare(strict_types=1);

namespace Controllers;

use Core\Ar;
use Core\Auth;
use Core\BaseController;
use Core\Request;
use Core\Response;

final class UsersController extends BaseController
{
    public function list(array $input): array
    {
        return Ar::all('User', [
            'company_id' => $this->companyId($input),
            'role' => $input['role'] ?? null,
            'is_active' => $input['isActive'] ?? null,
        ]);
    }

    public function show(array $input): array
    {
        Request::require($input, ['id']);
        $user = Ar::find('User', (string)$input['id']);
        if ($user === null) {
            Response::error('User not found', 404);
        }
        return $user;
    }

    public function create(array $input): array
    {
        $now = $this->now();
        return Ar::create('User', [
            'id' => $input['id'] ?? $this->uuid(),
            'company_id' => $this->companyId($input),
            'role' => $input['role'],
            'name' => $input['name'],
            'phone' => $input['phone'] ?? null,
            'email' => $input['email'] ?? null,
            'password_hash' => password_hash($input['password'], PASSWORD_DEFAULT),
            'must_change_password' => 1,
            'is_active' => 1,
            'created_at' => $now,
            'updated_at' => $now,
        ]);
    }

    public function setActive(array $input): array
    {
        $user = $this->target($input);
        if ((string)$user['id'] === Auth::principal()->userId && !$input['isActive']) {
            Response::error('Administrators cannot deactivate their own account', 422);
        }
        $this->beginWriteTransaction();
        try {
            $updated = Ar::update('User', (string)$user['id'], [
                'is_active' => $input['isActive'] ? 1 : 0,
                'updated_at' => $this->now(),
            ]);
            if (!$input['isActive']) {
                $this->revokeTokens((string)$user['id']);
            }
            $this->commitWriteTransaction();
            return $updated;
        } catch (\Throwable $error) {
            $this->rollbackWriteTransaction();
            throw $error;
        }
    }

    public function resetPassword(array $input): array
    {
        $user = $this->target($input);
        $this->beginWriteTransaction();
        try {
            $updated = Ar::update('User', (string)$user['id'], [
                'password_hash' => password_hash($input['password'], PASSWORD_DEFAULT),
                'must_change_password' => 1,
                'updated_at' => $this->now(),
            ]);
            $this->revokeTokens((string)$user['id']);
            $this->commitWriteTransaction();
            return $updated;
        } catch (\Throwable $error) {
            $this->rollbackWriteTransaction();
            throw $error;
        }
    }

    private function target(array $input): array
    {
        $user = Ar::find('User', (string)$input['id']);
        if ($user === null || (string)$user['company_id'] !== Auth::principal()->companyId) {
            Response::error('User not found', 404);
        }
        return $user;
    }

    private function revokeTokens(string $userId): void
    {
        $statement = $this->pdo()->prepare('update api_tokens set revoked_at = :revoked_at where user_id = :user_id and revoked_at is null');
        $statement->execute(['revoked_at' => $this->now(), 'user_id' => $userId]);
    }
}
