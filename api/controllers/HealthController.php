<?php

declare(strict_types=1);

namespace Controllers;

use Core\BaseController;
use Core\Config;

final class HealthController extends BaseController
{
    public function index(array $input): array
    {
        return [
            'ok' => true,
            'driver' => Config::get('db.driver', 'sqlite'),
            'time' => $this->now(),
            'usage' => '?cmd=health&action=index',
        ];
    }
}
