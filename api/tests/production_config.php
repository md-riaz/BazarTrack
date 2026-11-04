<?php

declare(strict_types=1);

require dirname(__DIR__) . '/core/Autoload.php';
Core\Autoload::register(dirname(__DIR__));

use Core\Config;

$valid = [
    'db' => ['driver' => 'mysql', 'mysql' => ['host' => 'db.internal', 'database' => 'bazartrack', 'user' => 'app', 'password' => 'strong-secret']],
    'app' => ['environment' => 'production', 'demo_mode' => false, 'debug' => false, 'allowed_origins' => ['https://app.example.com']],
];

Config::validateProduction($valid);

$invalid = [
    'demo mode' => ['app', 'demo_mode', true],
    'debug mode' => ['app', 'debug', true],
    'sqlite' => ['db', 'driver', 'sqlite'],
    'default DB password' => ['db.mysql', 'password', 'change-me'],
    'empty origins' => ['app', 'allowed_origins', []],
    'localhost origin' => ['app', 'allowed_origins', ['http://localhost']],
];

foreach ($invalid as $label => [$section, $key, $value]) {
    $config = $valid;
    $parts = explode('.', $section);
    if (count($parts) === 1) {
        $config[$section][$key] = $value;
    } else {
        $config[$parts[0]][$parts[1]][$key] = $value;
    }
    try {
        Config::validateProduction($config);
        throw new RuntimeException("Production config accepted {$label}");
    } catch (RuntimeException $error) {
        if (str_starts_with($error->getMessage(), 'Production config accepted')) {
            throw $error;
        }
    }
}

putenv('APP_ENV=production');
try {
    Config::values();
    throw new RuntimeException('Production started without api/config.php');
} catch (RuntimeException $error) {
    if ($error->getMessage() === 'Production started without api/config.php') {
        throw $error;
    }
}

echo "Production configuration validation passed.\n";
