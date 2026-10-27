<?php

declare(strict_types=1);

namespace Core;

final class RateLimiter
{
    public static function consume(string $key, int $limit, int $windowSeconds): void
    {
        $hash = hash('sha256', $key);
        $window = (int)(floor(time() / $windowSeconds) * $windowSeconds);
        $record = Ar::first('ApiRateLimit', ['bucket_key' => $hash, 'window_start' => $window]);
        if ($record === null) {
            Ar::create('ApiRateLimit', [
                'id' => bin2hex(random_bytes(16)),
                'bucket_key' => $hash,
                'window_start' => $window,
                'request_count' => 1,
            ]);
            return;
        }
        $count = (int)$record['request_count'] + 1;
        if ($count > $limit) {
            header('Retry-After: ' . max(1, $window + $windowSeconds - time()));
            Response::error('Too many requests', 429);
        }
        Ar::update('ApiRateLimit', (string)$record['id'], ['request_count' => $count]);
    }
}
