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

    public function changePassword(array $input): array
    {
        $principal = Auth::principal();
        $this->beginWriteTransaction();
        try {
            $user = $this->findUserById($principal->userId, true);
            if ($user === null || !$this->passwordMatches($user, $input['currentPassword'])) {
                $this->rollbackWriteTransaction();
                Response::error('Current password is incorrect', 422);
            }
            $token = $this->findTokenById($principal->tokenId, true);
            if ($token === null || $token['revoked_at'] !== null || (string)$token['user_id'] !== $principal->userId) {
                $this->rollbackWriteTransaction();
                Response::error('Invalid authentication token', 401);
            }
            $updated = Ar::update('User', $principal->userId, [
                'password_hash' => password_hash($input['newPassword'], PASSWORD_DEFAULT),
                'must_change_password' => 0,
                'updated_at' => $this->now(),
            ]);
            $statement = $this->pdo()->prepare('update api_tokens set revoked_at = :revoked_at where user_id = :user_id and id <> :current_token_id and revoked_at is null');
            $statement->execute([
                'revoked_at' => $this->now(),
                'user_id' => $principal->userId,
                'current_token_id' => $principal->tokenId,
            ]);
            $this->commitWriteTransaction();
            return ['changed' => true, 'user' => $this->publicUser($updated)];
        } catch (\Throwable $error) {
            $this->rollbackWriteTransaction();
            throw $error;
        }
    }

    private function findUserForLogin(string $login): ?array
    {
        $companyId = (string)Config::get('app.default_company_id', 'company1');
        foreach (['phone', 'email', 'id'] as $field) {
            $statement = $this->pdo()->prepare("select * from users where company_id = :company_id and {$field} = :login limit 1");
            $statement->execute(['company_id' => $companyId, 'login' => $login]);
            $user = $statement->fetch(\PDO::FETCH_ASSOC);
            if ($user !== false) {
                return $user;
            }
        }
        return null;
    }

    private function findUserById(string $id, bool $lock = false): ?array
    {
        $suffix = $lock && $this->pdo()->getAttribute(\PDO::ATTR_DRIVER_NAME) === 'mysql' ? ' for update' : '';
        $statement = $this->pdo()->prepare("select * from users where id = :id limit 1{$suffix}");
        $statement->execute(['id' => $id]);
        $user = $statement->fetch(\PDO::FETCH_ASSOC);
        return $user === false ? null : $user;
    }

    private function findTokenById(string $id, bool $lock = false): ?array
    {
        $suffix = $lock && $this->pdo()->getAttribute(\PDO::ATTR_DRIVER_NAME) === 'mysql' ? ' for update' : '';
        $statement = $this->pdo()->prepare("select * from api_tokens where id = :id limit 1{$suffix}");
        $statement->execute(['id' => $id]);
        $token = $statement->fetch(\PDO::FETCH_ASSOC);
        return $token === false ? null : $token;
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
