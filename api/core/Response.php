<?php

declare(strict_types=1);

namespace Core;

final class Response
{
    private static ?string $requestId = null;

    public static function json(mixed $data = null, int $status = 200): never
    {
        http_response_code($status);
        self::headers();
        echo json_encode([
            'data' => $data,
            'meta' => ['requestId' => self::requestId()],
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    public static function error(string $message, int $status = 400, array $details = []): never
    {
        http_response_code($status);
        self::headers();
        echo json_encode([
            'error' => [
                'message' => $message,
                'details' => $details,
                'requestId' => self::requestId(),
            ],
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    public static function requestId(): string
    {
        if (self::$requestId === null) {
            self::$requestId = bin2hex(random_bytes(12));
        }
        return self::$requestId;
    }

    private static function headers(): void
    {
        header('Content-Type: application/json; charset=utf-8');
        header('X-Request-Id: ' . self::requestId());
        header('X-Content-Type-Options: nosniff');
        header('Referrer-Policy: no-referrer');
        header('Cache-Control: no-store');
    }
}
