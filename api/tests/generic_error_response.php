<?php

declare(strict_types=1);

$source = file_get_contents(dirname(__DIR__) . '/index.php');
if ($source === false) {
    throw new RuntimeException('Unable to read API bootstrap');
}
if (!str_contains($source, "Response::error('Internal server error', \$status);")) {
    throw new RuntimeException('Unhandled exceptions must always use the generic response');
}
if (preg_match('/Response::error\([^;]*(?:getMessage|APP_DEBUG|debug)/i', $source) === 1) {
    throw new RuntimeException('Unhandled exception responses must not expose debug details');
}
echo "Generic unhandled exception response passed.\n";
