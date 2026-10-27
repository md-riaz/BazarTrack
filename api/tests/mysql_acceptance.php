<?php

declare(strict_types=1);

$base = getenv('API_BASE_URL') ?: 'http://api:8080/index.php';
$passed = 0;

function request(string $cmd, string $action, string $method = 'GET', array $body = [], ?string $token = null, array $headers = [], array $expected = [200]): array
{
    global $base;
    $url = $base . '?' . http_build_query(['cmd' => $cmd, 'action' => $action]);
    $requestHeaders = ['Accept: application/json', 'X-Client-Id: mysql-acceptance'];
    if ($token !== null) $requestHeaders[] = 'Authorization: Bearer ' . $token;
    foreach ($headers as $name => $value) $requestHeaders[] = $name . ': ' . $value;
    $options = ['http' => ['method' => $method, 'ignore_errors' => true, 'header' => implode("\r\n", $requestHeaders)]];
    if ($method !== 'GET') {
        $options['http']['header'] .= "\r\nContent-Type: application/json";
        $options['http']['content'] = json_encode($body, JSON_THROW_ON_ERROR);
    }
    $content = file_get_contents($url, false, stream_context_create($options));
    $statusLine = $http_response_header[0] ?? '';
    preg_match('/\s(\d{3})\s/', $statusLine, $match);
    $status = (int)($match[1] ?? 0);
    if (!in_array($status, $expected, true)) throw new RuntimeException("{$method} {$cmd}.{$action} returned {$status}: {$content}");
    return ['status' => $status, 'body' => json_decode((string)$content, true, 512, JSON_THROW_ON_ERROR)];
}

function check(bool $condition, string $message): void
{
    global $passed;
    if (!$condition) throw new RuntimeException($message);
    $passed++;
    echo "[PASS] {$message}\n";
}

request('setup', 'seedDemo', 'POST');
$manager = request('auth', 'login', 'POST', ['phone' => 'owner', 'password' => 'demo-pass'])['body']['data'];
$assistant = request('auth', 'login', 'POST', ['phone' => 'assistant', 'password' => 'demo-pass'])['body']['data'];
check($manager['user']['role'] === 'owner' && $assistant['user']['role'] === 'assistant', 'MySQL API demo roles login');

$giveHeaders = ['Idempotency-Key' => 'mysql-give-1'];
$give = request('money', 'give', 'POST', ['accountId' => 'acc1', 'amount' => 1000, 'entryDate' => '2026-10-26'], $manager['token'], $giveHeaders)['body']['data'];
$giveReplay = request('money', 'give', 'POST', ['accountId' => 'acc1', 'amount' => 1000, 'entryDate' => '2026-10-26'], $manager['token'], $giveHeaders)['body']['data'];
check((float)$give['accountBalance'] === 1000.0 && $giveReplay['idempotentReplay'] === true, 'MySQL money give is replay-safe');
request('money', 'give', 'POST', ['accountId' => 'acc1', 'amount' => 999], $manager['token'], $giveHeaders, [409]);
check(true, 'MySQL idempotency payload mismatch returns 409');

$bazar = request('bazars', 'create', 'POST', [
    'fundId' => 'fund1', 'accountId' => 'acc1', 'title' => 'MySQL Bazar', 'assignedTo' => 'assistant1', 'status' => 'open',
    'items' => [['name' => 'Rice', 'price' => 200, 'status' => 'done']],
], $manager['token'])['body']['data']['bazar'];
$closed = request('bazars', 'close', 'POST', ['id' => $bazar['id']], $assistant['token'])['body']['data'];
$closeReplay = request('bazars', 'close', 'POST', ['id' => $bazar['id']], $assistant['token'])['body']['data'];
check((float)$closed['accountBalance'] === 800.0 && $closeReplay['idempotentReplay'] === true, 'MySQL bazar close applies once');

$return = request('returns', 'create', 'POST', ['accountId' => 'acc1', 'amount' => 300, 'expectedReceiverId' => 'manager1'], $assistant['token'], ['Idempotency-Key' => 'mysql-return-1'])['body']['data']['request'];
$confirmed = request('returns', 'confirm', 'POST', ['id' => $return['id']], $manager['token'])['body']['data'];
$confirmReplay = request('returns', 'confirm', 'POST', ['id' => $return['id']], $manager['token'])['body']['data'];
check((float)$confirmed['accountBalance'] === 500.0 && $confirmReplay['idempotentReplay'] === true, 'MySQL two-step return confirmation applies once');

$reconcile = file_get_contents($base . '?' . http_build_query(['cmd'=>'ledger','action'=>'reconcile','accountId'=>'acc1']), false, stream_context_create(['http'=>['header'=>'Authorization: Bearer '.$manager['token']."\r\nX-Client-Id: mysql-acceptance"]]));
$reconcileData = json_decode((string)$reconcile, true, 512, JSON_THROW_ON_ERROR)['data'];
check($reconcileData['consistent'] === true, 'MySQL stored balance reconciles with ledger');

echo "MySQL API acceptance: {$passed} passed.\n";
