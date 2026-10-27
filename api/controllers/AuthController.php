<?php

declare(strict_types=1);

namespace Controllers;

use Core\Ar;
use Core\Auth;
use Core\BaseController;
use Core\Config;
use Core\Request;
use Core\Response;

final class AuthController extends BaseController
{
    public function login(array $input): array
    {
        $login = Request::string($input, 'phone', 190);
        $password = Request::string($input, 'password', 255);
        $user = $this->findUserForLogin($this->demoLoginAlias($login));
        if ($user === null || !$this->passwordMatches($user, $password)) {
            Response::error('Invalid credentials', 401);
        }
        if ((int)($user['is_active'] ?? 0) !== 1 || ($user['deleted_at'] ?? null) !== null) {
            Response::error('Invalid credentials', 401);
        }

        $token = bin2hex(random_bytes(32));
        Ar::create('ApiToken', [
            'id' => $this->uuid(),
            'token' => $token,
            'user_id' => $user['id'],
            'client_id' => isset($input['clientId']) ? substr(trim((string)$input['clientId']), 0, 120) : null,
            'created_at' => $this->now(),
            'last_used_at' => null,
            'revoked_at' => null,
        ]);

        return [
            'token' => $token,
            'tokenType' => 'Bearer',
            'user' => $this->publicUser($user),
        ];
    }

    public function me(array $input): array
    {
        $user = Ar::find('User', Auth::principal()->userId);
        if ($user === null) {
            Response::error('Invalid authentication token', 401);
        }
        return $this->publicUser($user);
    }

    /** @deprecated Use auth/me with a Bearer token. */
    public function user(array $input): array
    {
        return $this->me($input);
    }

    public function logout(array $input): array
    {
        Ar::update('ApiToken', Auth::principal()->tokenId, ['revoked_at' => $this->now()]);
        Auth::clear();
        return ['revoked' => true];
    }

    private function findUserForLogin(string $login): ?array
    {
        foreach (['phone', 'email', 'id'] as $field) {
            $user = Ar::first('User', [
                'company_id' => Config::get('app.default_company_id', 'company1'),
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
        $demoMode = Config::get('app.environment', 'production') === 'development'
            && (bool)Config::get('app.demo_mode', false);
        if ($demoMode && $password === 'demo-pass' && in_array($user['id'] ?? '', ['admin1', 'manager1', 'assistant1'], true)) {
            return true;
        }
        $hash = $user['password_hash'] ?? null;
        return is_string($hash) && $hash !== '' && password_verify($password, $hash);
    }

    private function demoLoginAlias(string $login): string
    {
        $demoMode = Config::get('app.environment', 'production') === 'development'
            && (bool)Config::get('app.demo_mode', false);
        if (!$demoMode) {
            return $login;
        }
        return match ($login) {
            '01000-ADMIN', 'admin' => 'admin1',
            '01900-XXXXXX', 'owner' => 'manager1',
            '01711-XXXXXX', 'assistant' => 'assistant1',
            default => $login,
        };
    }

    private function publicUser(array $user): array
    {
        unset($user['password_hash'], $user['deleted_at']);
        return $user;
    }
}
