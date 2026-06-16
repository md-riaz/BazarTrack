<?php

declare(strict_types=1);

namespace Core;

final class Autoload
{
    public static function register(string $baseDir): void
    {
        spl_autoload_register(function (string $class) use ($baseDir): void {
            $prefixes = [
                'Core\\' => $baseDir . '/core/',
                'Controllers\\' => $baseDir . '/controllers/',
            ];

            foreach ($prefixes as $prefix => $dir) {
                if (!str_starts_with($class, $prefix)) {
                    continue;
                }

                $relative = substr($class, strlen($prefix));
                $file = $dir . str_replace('\\', '/', $relative) . '.php';
                if (is_file($file)) {
                    require $file;
                }
                return;
            }

            if (!str_contains($class, '\\')) {
                $file = $baseDir . '/models/' . $class . '.php';
                if (is_file($file)) {
                    require $file;
                }
            }
        });
    }
}
