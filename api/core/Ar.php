<?php

declare(strict_types=1);

namespace Core;

final class Ar
{
    public static function all(string $class, array $where = [], int $limit = 100): array
    {
        $relation = $class::where(self::whereHash($where))->limit(max(1, min($limit, 500)));
        return $class::public_array($relation->to_a());
    }

    public static function find(string $class, string $id): ?array
    {
        $record = $class::where(['id' => $id])->first();
        return $record ? $record->to_array_public() : null;
    }

    public static function create(string $class, array $data): array
    {
        return $class::create($data, false)->to_array_public();
    }

    public static function update(string $class, string $id, array $data): array
    {
        $record = $class::where(['id' => $id])->first();
        if (!$record) {
            Response::error('Record not found', 404);
        }
        $record->set_attributes($data);
        $record->save(false);
        return $record->to_array_public();
    }

    public static function first(string $class, array $where): ?array
    {
        $record = $class::where(self::whereHash($where))->first();
        return $record ? $record->to_array_public() : null;
    }

    public static function connection()
    {
        return \ActiveRecord\ConnectionManager::get_connection();
    }

    private static function whereHash(array $where): array
    {
        return array_filter($where, static fn ($value): bool => $value !== null && $value !== '');
    }
}
