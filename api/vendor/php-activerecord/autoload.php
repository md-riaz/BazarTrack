<?php

declare(strict_types=1);

require_once __DIR__ . '/ActiveRecord.php';
require_once __DIR__ . '/lib/Utils.php';

spl_autoload_register(static function (string $class): void {
    $prefix = 'ActiveRecord\\';
    if (!str_starts_with($class, $prefix)) {
        return;
    }

    $relative = substr($class, strlen($prefix));
    $file = __DIR__ . '/lib/' . str_replace('\\', '/', $relative) . '.php';
    if (is_file($file)) {
        require_once $file;
    }
});
