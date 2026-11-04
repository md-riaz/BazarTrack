<?php

declare(strict_types=1);

namespace Core;

final class Config
{
    private static ?array $values = null;

    public static function get(string $key, mixed $default = null): mixed
    {
        $values = self::values();
        foreach (explode('.', $key) as $part) {
            if (!is_array($values) || !array_key_exists($part, $values)) {
                return $default;
            }
            $values = $values[$part];
        }
        return $values;
    }

    public static function values(): array
    {
        if (self::$values !== null) {
            return self::$values;
        }

        $root = dirname(__DIR__);
        $configPath = $root . '/config.php';
        $environment = strtolower(trim((string)(getenv('APP_ENV') ?: 'development')));
        if (!is_file($configPath)) {
            if ($environment === 'production') {
                throw new \RuntimeException('api/config.php is required in production');
            }
            $configPath = $root . '/config.example.php';
        }

        $values = require $configPath;
        if (!is_array($values)) {
            throw new \RuntimeException('API configuration must return an array');
        }
        $configuredEnvironment = strtolower(trim((string)($values['app']['environment'] ?? $environment)));
        if ($environment === 'production' || $configuredEnvironment === 'production') {
            if (basename($configPath) !== 'config.php') {
                throw new \RuntimeException('api/config.php is required in production');
            }
            self::validateProduction($values);
        }
        return self::$values = $values;
    }

    public static function validateProduction(array $values): void
    {
        $app = $values['app'] ?? [];
        $db = $values['db'] ?? [];
        $mysql = $db['mysql'] ?? [];
        $origins = $app['allowed_origins'] ?? [];

        if (($app['demo_mode'] ?? false) || ($app['debug'] ?? false)) {
            throw new \RuntimeException('Demo and debug modes must be disabled in production');
        }
        if (($db['driver'] ?? '') !== 'mysql') {
            throw new \RuntimeException('Production requires the MySQL database driver');
        }
        foreach (['host', 'database', 'user', 'password'] as $field) {
            if (!is_string($mysql[$field] ?? null) || trim($mysql[$field]) === '') {
                throw new \RuntimeException("Production MySQL {$field} is required");
            }
        }
        if (hash_equals('change-me', (string)$mysql['password'])) {
            throw new \RuntimeException('Default database credentials are forbidden in production');
        }
        if (!is_array($origins) || $origins === []) {
            throw new \RuntimeException('Explicit production origins are required');
        }
        foreach ($origins as $origin) {
            $host = parse_url((string)$origin, PHP_URL_HOST);
            if (!is_string($host) || $host === '' || in_array(strtolower($host), ['localhost', '127.0.0.1', '::1'], true)) {
                throw new \RuntimeException('Localhost and invalid origins are forbidden in production');
            }
        }
    }
}
