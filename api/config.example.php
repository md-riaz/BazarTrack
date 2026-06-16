<?php

return [
    // Development default: sqlite. Production: set driver=mysql and fill host/db/user/password.
    'db' => [
        'driver' => getenv('DB_DRIVER') ?: 'sqlite', // sqlite|mysql
        'sqlite_path' => getenv('SQLITE_PATH') ?: __DIR__ . '/storage/dev.sqlite',
        'mysql' => [
            'host' => getenv('DB_HOST') ?: '127.0.0.1',
            'port' => getenv('DB_PORT') ?: '3306',
            'database' => getenv('DB_DATABASE') ?: 'bazartrack',
            'user' => getenv('DB_USER') ?: 'bazartrack',
            'password' => getenv('DB_PASSWORD') ?: 'change-me',
            'charset' => 'utf8mb4',
        ],
    ],
    'app' => [
        'default_company_id' => getenv('DEFAULT_COMPANY_ID') ?: 'company1',
    ],
    'seed' => [
        'company_name' => getenv('INITIAL_COMPANY_NAME') ?: 'BazarTrack Office',
        'admin_id' => getenv('INITIAL_ADMIN_ID') ?: 'admin1',
        'admin_name' => getenv('INITIAL_ADMIN_NAME') ?: 'System Admin',
        'admin_email' => getenv('INITIAL_ADMIN_EMAIL') ?: 'admin@example.com',
        'admin_phone' => getenv('INITIAL_ADMIN_PHONE') ?: null,
        'admin_password' => getenv('INITIAL_ADMIN_PASSWORD') ?: 'admin123',
    ],
];
