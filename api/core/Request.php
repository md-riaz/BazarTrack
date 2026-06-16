<?php

declare(strict_types=1);

namespace Core;

final class Request
{
    public static function method(): string
    {
        return strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
    }

    public static function input(): array
    {
        $input = $_GET + $_POST;
        $raw = file_get_contents('php://input') ?: '';
        if ($raw !== '') {
            $json = json_decode($raw, true);
            if (is_array($json)) {
                $input = $json + $input;
            }
        }
        unset($input['cmd'], $input['action']);
        return $input;
    }

    public static function require(array $data, array $fields): void
    {
        $missing = [];
        foreach ($fields as $field) {
            if (!array_key_exists($field, $data) || $data[$field] === '' || $data[$field] === null) {
                $missing[] = $field;
            }
        }
        if ($missing !== []) {
            Response::error('Missing required fields', 422, ['fields' => $missing]);
        }
    }

    public static function header(string $name): ?string
    {
        $key = 'HTTP_' . strtoupper(str_replace('-', '_', $name));
        return $_SERVER[$key] ?? null;
    }
}
