<?php

declare(strict_types=1);

namespace Controllers;

use Core\Ar;
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
        Request::require($input, ['role', 'name']);
        $now = $this->now();
        return Ar::create('User', [
            'id' => $input['id'] ?? $this->uuid(),
            'company_id' => $this->companyId($input),
            'role' => $input['role'],
            'name' => $input['name'],
            'phone' => $input['phone'] ?? null,
            'email' => $input['email'] ?? null,
            'password_hash' => isset($input['password']) ? password_hash((string)$input['password'], PASSWORD_DEFAULT) : null,
            'is_active' => 1,
            'created_at' => $now,
            'updated_at' => $now,
        ]);
    }
}
