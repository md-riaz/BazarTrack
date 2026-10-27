<?php

declare(strict_types=1);

namespace Core;

final class Principal
{
    public function __construct(
        public readonly string $userId,
        public readonly string $companyId,
        public readonly string $role,
        public readonly string $tokenId,
    ) {
    }

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    public function isManager(): bool
    {
        return $this->role === 'owner';
    }

    public function isAssistant(): bool
    {
        return $this->role === 'assistant';
    }
}
