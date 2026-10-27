<?php

declare(strict_types=1);

namespace Core;

final class Auth
{
    private static ?Principal $principal = null;
    private static ?string $token = null;

    public static function authenticate(): Principal
    {
        if (self::$principal !== null) {
            return self::$principal;
        }

        $token = Request::bearerToken();
        if ($token === null || preg_match('/^[a-f0-9]{64}$/', $token) !== 1) {
            Response::error('Authentication required', 401);
        }

        $record = Ar::first('ApiToken', ['token' => $token]);
        if ($record === null || $record['revoked_at'] !== null) {
            Response::error('Invalid authentication token', 401);
        }

        $user = Ar::find('User', (string)$record['user_id']);
        if ($user === null || (int)($user['is_active'] ?? 0) !== 1 || ($user['deleted_at'] ?? null) !== null) {
            Response::error('Invalid authentication token', 401);
        }

        Ar::update('ApiToken', (string)$record['id'], ['last_used_at' => gmdate('Y-m-d H:i:s')]);
        self::$token = $token;
        self::$principal = new Principal(
            (string)$user['id'],
            (string)$user['company_id'],
            (string)$user['role'],
            (string)$record['id'],
        );
        return self::$principal;
    }

    public static function principal(): Principal
    {
        return self::$principal ?? self::authenticate();
    }

    public static function token(): ?string
    {
        return self::$token;
    }

    public static function clear(): void
    {
        self::$principal = null;
        self::$token = null;
    }
}
