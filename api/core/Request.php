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
        $maxBytes = max(1024, (int)Config::get('app.max_request_bytes', 1048576));
        if (strlen($raw) > $maxBytes) {
            Response::error('Request body too large', 413);
        }
        if ($raw !== '') {
            try {
                $json = json_decode($raw, true, 64, JSON_THROW_ON_ERROR);
            } catch (\JsonException) {
                Response::error('Malformed JSON body', 400);
            }
            if (!is_array($json)) {
                Response::error('JSON body must be an object', 400);
            }
            $input = $json + $input;
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
        $value = $_SERVER[$key] ?? null;
        return is_string($value) && $value !== '' ? trim($value) : null;
    }

    public static function bearerToken(): ?string
    {
        $header = self::header('Authorization');
        if ($header === null || preg_match('/^Bearer\s+(.+)$/i', $header, $matches) !== 1) {
            return null;
        }
        return trim($matches[1]);
    }

    public static function string(array $data, string $field, int $maxLength = 190): string
    {
        self::require($data, [$field]);
        if (!is_string($data[$field])) {
            Response::error('Invalid field', 422, ['field' => $field]);
        }
        $value = trim($data[$field]);
        if ($value === '' || strlen($value) > $maxLength) {
            Response::error('Invalid field', 422, ['field' => $field]);
        }
        return $value;
    }

    public static function enum(array $data, string $field, array $allowed): string
    {
        $value = self::string($data, $field, 50);
        if (!in_array($value, $allowed, true)) {
            Response::error('Invalid field', 422, ['field' => $field, 'allowed' => $allowed]);
        }
        return $value;
    }

    public static function optionalEnum(array $data, string $field, array $allowed): ?string
    {
        if (!array_key_exists($field, $data) || $data[$field] === null || $data[$field] === '') {
            return null;
        }
        if (!is_string($data[$field])) {
            Response::error('Invalid field', 422, ['field' => $field, 'allowed' => $allowed]);
        }
        $value = trim($data[$field]);
        if (!in_array($value, $allowed, true)) {
            Response::error('Invalid field', 422, ['field' => $field, 'allowed' => $allowed]);
        }
        return $value;
    }

    public static function optionalArray(array $data, string $field, int $maxItems = 100): array
    {
        if (!array_key_exists($field, $data) || $data[$field] === null) {
            return [];
        }
        if (!is_array($data[$field]) || !array_is_list($data[$field]) || count($data[$field]) > $maxItems) {
            Response::error('Invalid field', 422, ['field' => $field]);
        }
        return $data[$field];
    }

    public static function positiveAmount(array $data, string $field = 'amount'): float
    {
        self::require($data, [$field]);
        if (!is_numeric($data[$field])) {
            Response::error('Invalid amount', 422, ['field' => $field]);
        }
        $amount = round((float)$data[$field], 2);
        if (!is_finite($amount) || $amount <= 0 || $amount > 9999999999.99) {
            Response::error('Invalid amount', 422, ['field' => $field]);
        }
        return $amount;
    }
}
