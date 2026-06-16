<?php

declare(strict_types=1);

use Core\Router;
use Core\Response;

require __DIR__ . '/core/Autoload.php';

Core\Autoload::register(__DIR__);
Core\ActiveRecordBootstrap::boot();

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Idempotency-Key, X-Client-Id');
header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

try {
    Router::dispatch();
} catch (Throwable $e) {
    Response::error($e->getMessage(), $e->getCode() >= 400 && $e->getCode() < 600 ? $e->getCode() : 500);
}
