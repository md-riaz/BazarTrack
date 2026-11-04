<?php

declare(strict_types=1);

namespace Core;

final class RequestLogger
{
    private static ?float $startedAt = null;

    public static function register(): void
    {
        self::$startedAt = microtime(true);
        register_shutdown_function(static function (): void {
            $status = http_response_code();
            if (!is_int($status) || $status < 100) {
                $status = 500;
            }
            error_log(json_encode(self::context($status), JSON_UNESCAPED_SLASHES | JSON_THROW_ON_ERROR));
        });
    }

    public static function logException(\Throwable $error): void
    {
        error_log(json_encode(self::exceptionContext($error), JSON_UNESCAPED_SLASHES | JSON_THROW_ON_ERROR));
    }

    public static function exceptionContext(\Throwable $error): array
    {
        return [
            'event' => 'api_exception',
            'requestId' => Response::requestId(),
            'exception' => get_class($error),
        ];
    }

    public static function context(int $status): array
    {
        $startedAt = self::$startedAt ?? microtime(true);
        return [
            'requestId' => Response::requestId(),
            'method' => strtoupper((string)($_SERVER['REQUEST_METHOD'] ?? 'GET')),
            'cmd' => self::routeValue($_GET['cmd'] ?? null),
            'action' => self::routeValue($_GET['action'] ?? null),
            'status' => $status,
            'durationMs' => round((microtime(true) - $startedAt) * 1000, 2),
        ];
    }

    private static function routeValue(mixed $value): ?string
    {
        if (!is_string($value) || preg_match('/^[A-Za-z][A-Za-z0-9_-]{0,63}$/', $value) !== 1) {
            return null;
        }
        return $value;
    }
}
