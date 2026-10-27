<?php

declare(strict_types=1);

namespace Core;

final class Validator
{
    public static function validate(string $cmd, string $action, array &$input): void
    {
        $route = strtolower($cmd) . '.' . $action;
        if (isset($input['limit'])) {
            if (!is_numeric($input['limit']) || (int)$input['limit'] < 1 || (int)$input['limit'] > 500) {
                Response::error('Invalid field', 422, ['field' => 'limit']);
            }
            $input['limit'] = (int)$input['limit'];
        }
        foreach (['fundId', 'accountId', 'assistantId', 'assignedTo', 'expectedReceiverId', 'userId', 'id'] as $field) {
            if (isset($input[$field]) && (!is_string($input[$field]) || strlen(trim($input[$field])) > 120)) {
                Response::error('Invalid field', 422, ['field' => $field]);
            }
        }

        if ($route === 'users.create') {
            $input['role'] = Request::enum($input, 'role', ['admin', 'owner', 'assistant']);
            $input['name'] = Request::string($input, 'name', 190);
        }
        if ($route === 'bazars.create') {
            $input['title'] = Request::string($input, 'title', 190);
            $input['status'] = Request::optionalEnum($input, 'status', ['draft', 'open']) ?? 'draft';
            $items = Request::optionalArray($input, 'items', 200);
            foreach ($items as $index => $item) {
                if (!is_array($item)) {
                    Response::error('Invalid field', 422, ['field' => "items.$index"]);
                }
                Request::string($item, 'name', 190);
                Request::optionalEnum($item, 'status', ['pending', 'done', 'not_found', 'cancelled']);
                self::optionalScalar($item, 'quantity', "items.$index.quantity", 100);
                self::optionalString($item, 'note', "items.$index.note", 2000);
                if (isset($item['price']) && (!is_numeric($item['price']) || (float)$item['price'] < 0)) {
                    Response::error('Invalid field', 422, ['field' => "items.$index.price"]);
                }
            }
        }
        if ($route === 'bazars.addItem') {
            $input['name'] = Request::string($input, 'name', 190);
            Request::optionalEnum($input, 'status', ['pending', 'done', 'not_found', 'cancelled']);
            self::optionalScalar($input, 'quantity', 'quantity', 100);
            self::optionalString($input, 'note', 'note', 2000);
        }
        if ($route === 'bazars.updateItem') {
            Request::optionalEnum($input, 'status', ['pending', 'done', 'not_found', 'cancelled']);
            self::optionalScalar($input, 'quantity', 'quantity', 100);
            self::optionalString($input, 'note', 'note', 2000);
            if (isset($input['price']) && (!is_numeric($input['price']) || (float)$input['price'] < 0)) {
                Response::error('Invalid field', 422, ['field' => 'price']);
            }
        }
        if (in_array($route, ['money.give', 'returns.create'], true)) {
            $input['amount'] = Request::positiveAmount($input);
        }
        if (isset($input['status'])) {
            $allowed = match (strtolower($cmd)) {
                'funds' => ['active', 'inactive'],
                'accounts' => ['active', 'closed'],
                'returns' => ['pending', 'confirmed', 'rejected'],
                'bazars' => ['draft', 'open', 'closed', 'cancelled'],
                default => null,
            };
            if ($allowed !== null) {
                Request::optionalEnum($input, 'status', $allowed);
            }
        }
    }

    private static function optionalString(array $data, string $field, string $path, int $maxLength): void
    {
        if (!array_key_exists($field, $data) || $data[$field] === null) {
            return;
        }
        if (!is_string($data[$field]) || strlen($data[$field]) > $maxLength) {
            Response::error('Invalid field', 422, ['field' => $path]);
        }
    }

    private static function optionalScalar(array $data, string $field, string $path, int $maxLength): void
    {
        if (!array_key_exists($field, $data) || $data[$field] === null) {
            return;
        }
        if ((!is_string($data[$field]) && !is_int($data[$field]) && !is_float($data[$field])) || strlen((string)$data[$field]) > $maxLength) {
            Response::error('Invalid field', 422, ['field' => $path]);
        }
    }
}
