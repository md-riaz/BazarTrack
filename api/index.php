<?php

declare(strict_types=1);

ini_set('display_errors', '0');
ini_set('display_startup_errors', '0');

use Core\Config;
use Core\Cors;
use Core\Response;
use Core\Router;

require __DIR__ . '/core/Autoload.php';

Core\Autoload::register(__DIR__);
Core\ActiveRecordBootstrap::boot();
Cors::apply();

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

try {
    Router::dispatch();
} catch (Throwable $e) {
    $status = $e->getCode() >= 400 && $e->getCode() < 600 ? $e->getCode() : 500;
    error_log(json_encode([
        'requestId' => Response::requestId(),
        'status' => $status,
        'exception' => get_class($e),
        'message' => $e->getMessage(),
    ], JSON_UNESCAPED_SLASHES));
    $debug = (bool)Config::get('app.debug', false);
    Response::error($debug ? $e->getMessage() : 'Internal server error', $status);
}
