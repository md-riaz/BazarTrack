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

        $configPath = dirname(__DIR__) . '/config.php';
        if (!is_file($configPath)) {
            $configPath = dirname(__DIR__) . '/config.example.php';
        }

        self::$values = require $configPath;
        return self::$values;
    }
}
