<?php

declare(strict_types=1);

require dirname(__DIR__) . '/core/Autoload.php';
Core\Autoload::register(dirname(__DIR__));

use Core\RequestLogger;

$_SERVER['REQUEST_METHOD'] = 'POST';
$_SERVER['HTTP_AUTHORIZATION'] = 'Bearer super-secret-token';
$_GET = ['cmd' => 'auth', 'action' => 'login', 'password' => 'never-log-me'];
$context = RequestLogger::context(401);
$exception = RequestLogger::exceptionContext(new RuntimeException('secret-config-value'));
$encoded = json_encode([$context, $exception], JSON_THROW_ON_ERROR);
foreach (['requestId', 'method', 'cmd', 'action', 'status', 'durationMs'] as $field) {
    if (!array_key_exists($field, $context)) {
        throw new RuntimeException("Missing structured log field {$field}");
    }
}
foreach (['super-secret-token', 'never-log-me', 'secret-config-value', 'authorization', 'password'] as $secret) {
    if (stripos($encoded, $secret) !== false) {
        throw new RuntimeException("Structured log leaked {$secret}");
    }
}
echo "Safe structured request logging passed.\n";
