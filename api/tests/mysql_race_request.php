<?php

declare(strict_types=1);

$token = getenv('TOKEN');
$body = json_encode([
    'accountId' => 'acc1',
    'amount' => 100,
    'entryDate' => '2026-10-26',
    'note' => 'Concurrent MySQL verification',
], JSON_THROW_ON_ERROR);
$context = stream_context_create(['http' => [
    'method' => 'POST',
    'ignore_errors' => true,
    'header' => "Content-Type: application/json\r\nAuthorization: Bearer {$token}\r\nX-Client-Id: mysql-race\r\nIdempotency-Key: mysql-concurrent-same",
    'content' => $body,
]]);
echo file_get_contents('http://api:8080/index.php?cmd=money&action=give', false, $context);
