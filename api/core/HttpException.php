<?php

declare(strict_types=1);

namespace Core;

use RuntimeException;

final class HttpException extends RuntimeException
{
    public function __construct(string $message, int $status = 400)
    {
        parent::__construct($message, $status);
    }
}
