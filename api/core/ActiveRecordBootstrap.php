<?php

declare(strict_types=1);

namespace Core;

final class ActiveRecordBootstrap
{
    private static bool $booted = false;

    public static function boot(): void
    {
        if (self::$booted) {
            return;
        }

        $library = dirname(__DIR__) . '/vendor/php-activerecord/autoload.php';
        if (!is_file($library)) {
            Response::error('Bundled php-activerecord library missing at api/vendor/php-activerecord/autoload.php', 500);
        }

        require_once $library;

        $connection = self::connectionString();

        \ActiveRecord\Config::initialize(static function ($cfg) use ($connection): void {
            $cfg->set_connections(['development' => $connection], 'development');
        });

        self::$booted = true;
    }

    public static function connectionString(): string
    {
        $driver = Config::get('db.driver', 'sqlite');
        if ($driver === 'mysql') {
            $mysql = Config::get('db.mysql', []);
            $user = rawurlencode((string)($mysql['user'] ?? 'bazartrack'));
            $password = rawurlencode((string)($mysql['password'] ?? ''));
            $host = $mysql['host'] ?? '127.0.0.1';
            $port = $mysql['port'] ?? '3306';
            $database = $mysql['database'] ?? 'bazartrack';
            $charset = $mysql['charset'] ?? 'utf8mb4';
            return "mysql://{$user}:{$password}@{$host}:{$port}/{$database}?charset={$charset}";
        }

        $path = Config::get('db.sqlite_path', dirname(__DIR__) . '/storage/dev.sqlite');
        $dir = dirname($path);
        if (!is_dir($dir)) {
            mkdir($dir, 0775, true);
        }
        if (!is_file($path)) {
            touch($path);
        }
        $normalized = str_replace('\\', '/', $path);
        if (preg_match('/^[A-Za-z]:\//', $normalized) === 1) {
            return 'sqlite://windows(' . rawurlencode(substr($normalized, 0, 2)) . substr($normalized, 2) . ')';
        }
        return 'sqlite://unix(' . $normalized . ')';
    }
}
