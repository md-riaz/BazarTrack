<?php

declare(strict_types=1);

class User extends BaseModel
{
    public static string $table_name = 'users';

    public function to_array_public(): array
    {
        $user = parent::to_array_public();
        unset($user['password_hash'], $user['deleted_at']);
        return $user;
    }
}
