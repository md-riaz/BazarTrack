<?php

declare(strict_types=1);

ini_set('display_errors', '0');
ini_set('display_startup_errors', '0');

use Core\Config;
use Core\Cors;
use Core\RequestLogger;
use Core\Response;
use Core\Router;

require __DIR__ . '/core/Autoload.php';

Core\Autoload::register(__DIR__);
RequestLogger::register();

try {
    Core\ActiveRecordBootstrap::boot();
    Cors::apply();
    if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
        http_response_code(204);
        exit;
    }
    Router::dispatch();
} catch (Throwable $e) {
    $status = $e->getCode() >= 400 && $e->getCode() < 600 ? $e->getCode() : 500;
    RequestLogger::logException($e);
    Response::error('Internal server error', $status);
}
