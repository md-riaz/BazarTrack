<?php

declare(strict_types=1);

namespace Core;

final class Cors
{
    public static function apply(): void
    {
        $origin = Request::header('Origin');
        $allowed = Config::get('app.allowed_origins', []);
        if ($origin !== null && in_array($origin, is_array($allowed) ? $allowed : [], true)) {
            header('Access-Control-Allow-Origin: ' . $origin);
            header('Vary: Origin');
        }
        header('Access-Control-Allow-Headers: Authorization, Content-Type, Idempotency-Key, X-Client-Id');
        header('Access-Control-Allow-Methods: GET, POST, PATCH, OPTIONS');
        header('Access-Control-Max-Age: 600');
    }
}
