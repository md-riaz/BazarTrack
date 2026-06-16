<?php

declare(strict_types=1);

namespace Controllers;

use Core\Ar;
use Core\BaseController;
use Core\Request;
use Core\Response;

final class AuthController extends BaseController
{
    public function login(array $input): array
    {
        Request::require($input, ['phone', 'password']);
        $phone = trim((string)$input['phone']);
        $password = (string)$input['password'];
        $phone = $this->demoLoginAlias($phone);
        $user = $this->findUserForLogin($phone);
        if ($user === null || !$this->passwordMatches($user, $password)) {
            Response::error('Invalid credentials', 401);
        }
        if ((int)($user['is_active'] ?? 0) !== 1) {
            Response::error('User is inactive', 403);
        }

        return [
            'token' => $this->tokenFor((string)$user['id']),
            'user' => $this->publicUser($user),
        ];
    }

    public function user(array $input): array
    {
        Request::require($input, ['token']);
        $userId = $this->userIdFromToken((string)$input['token']);
        $user = Ar::find('User', $userId);
        if ($user === null) {
            Response::error('User not found', 404);
        }
        return $this->publicUser($user);
    }

    private function findUserForLogin(string $login): ?array
    {
        foreach (['phone', 'email', 'id'] as $field) {
            $user = Ar::first('User', [
                'company_id' => $this->companyId([]),
                $field => $login,
            ]);
            if ($user !== null) {
                return $user;
            }
        }
        return null;
    }

    private function passwordMatches(array $user, string $password): bool
    {
        if ($password === 'demo-pass' && in_array($user['id'] ?? '', ['admin1', 'manager1', 'assistant1'], true)) {
            return true;
        }
        $hash = $user['password_hash'] ?? null;
        if (is_string($hash) && $hash !== '') {
            return password_verify($password, $hash);
        }
        return $password === 'demo-pass';
    }

    private function demoLoginAlias(string $login): string
    {
        return match ($login) {
            '01000-ADMIN', 'admin' => 'admin1',
            '01900-XXXXXX', 'owner' => 'manager1',
            '01711-XXXXXX', 'assistant' => 'assistant1',
            default => $login,
        };
    }

    private function tokenFor(string $userId): string
    {
        return 'api-token:' . base64_encode($userId);
    }

    private function userIdFromToken(string $token): string
    {
        if (!str_starts_with($token, 'api-token:')) {
            Response::error('Invalid token', 401);
        }
        $decoded = base64_decode(substr($token, strlen('api-token:')), true);
        if ($decoded === false || $decoded === '') {
            Response::error('Invalid token', 401);
        }
        return $decoded;
    }

    private function publicUser(array $user): array
    {
        unset($user['password_hash']);
        return $user;
    }
}
