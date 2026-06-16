<?php

declare(strict_types=1);

namespace Core;

use PDO;

abstract class BaseController
{
    protected function now(): string
    {
        return gmdate('Y-m-d H:i:s');
    }

    protected function uuid(): string
    {
        $bytes = random_bytes(16);
        $bytes[6] = chr((ord($bytes[6]) & 0x0f) | 0x40);
        $bytes[8] = chr((ord($bytes[8]) & 0x3f) | 0x80);
        return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($bytes), 4));
    }

    protected function companyId(array $input): string
    {
        return (string)($input['companyId'] ?? Config::get('app.default_company_id', 'company1'));
    }

    protected function idempotencyKey(): ?string
    {
        return Request::header('Idempotency-Key') ?? Request::header('X-Idempotency-Key');
    }

    protected function db()
    {
        return Ar::connection();
    }

    protected function pdo(): PDO
    {
        return $this->db()->connection;
    }

    protected function one(string $sql, array $params = []): ?array
    {
        $stmt = $this->pdo()->prepare($sql);
        $stmt->execute($params);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return $row === false ? null : $row;
    }

    protected function many(string $sql, array $params = []): array
    {
        $stmt = $this->pdo()->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}
