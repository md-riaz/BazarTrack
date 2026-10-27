<?php

declare(strict_types=1);

$base = 'http://api:8080/index.php';
$loginContext = stream_context_create(['http' => [
    'method' => 'POST',
    'header' => "Content-Type: application/json\r\nX-Client-Id: mysql-race",
    'content' => json_encode(['phone' => 'owner', 'password' => 'demo-pass'], JSON_THROW_ON_ERROR),
]]);
$login = json_decode((string)file_get_contents($base . '?cmd=auth&action=login', false, $loginContext), true, 512, JSON_THROW_ON_ERROR);
$token = $login['data']['token'] ?? null;
if (!is_string($token)) {
    fwrite(STDERR, json_encode($login));
    exit(1);
}
echo $token;
