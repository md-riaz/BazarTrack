<?php

declare(strict_types=1);

abstract class BaseModel extends ActiveRecord\Model
{
    public function to_array_public(): array
    {
        return $this->attributes();
    }

    public static function public_array(array $records): array
    {
        return array_map(static fn ($record): array => $record->to_array_public(), $records);
    }
}
