<?php

declare(strict_types=1);

namespace Core;

use PDO;

final class Schema
{
    public static function migrate(PDO $db): void
    {
        if (($db->getAttribute(PDO::ATTR_DRIVER_NAME) ?: '') === 'sqlite') {
            $db->exec('pragma foreign_keys = on');
        }
        self::refuseUnmigratableLedgerHistory($db);
        MigrationRunner::migrate($db, self::migrations());
        self::installLedgerImmutabilityGuards($db);
        self::assertCurrentSchema($db);
    }

    private static function refuseUnmigratableLedgerHistory(PDO $db): void
    {
        $columns = self::columnNames($db, 'ledger_entries');
        if ($columns === []) {
            return;
        }
        $count = (int)$db->query('select count(*) from ledger_entries')->fetchColumn();
        if ($count === 0) {
            return;
        }
        $snapshotColumns = ['balance_before', 'balance_after', 'ledger_sequence'];
        if (array_diff($snapshotColumns, $columns) !== []) {
            throw new \RuntimeException(
                'Ledger history without audit snapshots cannot be upgraded in place. Back up and import into a freshly migrated database.'
            );
        }
        $missing = (int)$db->query(
            'select count(*) from ledger_entries where balance_before is null or balance_after is null or ledger_sequence is null'
        )->fetchColumn();
        if ($missing > 0) {
            throw new \RuntimeException(
                'Ledger history with incomplete audit snapshots cannot be upgraded in place. Back up and import into a freshly migrated database.'
            );
        }
    }

    private static function installLedgerImmutabilityGuards(PDO $db): void
    {
        if ($db->getAttribute(PDO::ATTR_DRIVER_NAME) === 'mysql') {
            foreach ([
                ['ledger_entries_no_update', 'before update on ledger_entries for each row signal sqlstate \'45000\' set message_text = \'Ledger entries are immutable\''],
                ['ledger_entries_no_delete', 'before delete on ledger_entries for each row signal sqlstate \'45000\' set message_text = \'Ledger entries are immutable\''],
            ] as [$name, $body]) {
                $check = $db->prepare('select count(*) from information_schema.triggers where trigger_schema = database() and trigger_name = :name');
                $check->execute(['name' => $name]);
                if ((int)$check->fetchColumn() === 0) {
                    $db->exec("create trigger {$name} {$body}");
                }
            }
            return;
        }
        $db->exec("create trigger if not exists ledger_entries_no_update before update on ledger_entries begin select raise(abort, 'Ledger entries are immutable'); end");
        $db->exec("create trigger if not exists ledger_entries_no_delete before delete on ledger_entries begin select raise(abort, 'Ledger entries are immutable'); end");
    }

    private static function assertCurrentSchema(PDO $db): void
    {
        foreach ([
            'money_entries' => ['client_id', 'request_fingerprint'],
            'money_return_requests' => ['client_id', 'request_fingerprint'],
            'ledger_entries' => ['balance_before', 'balance_after', 'reverses_ledger_entry_id', 'ledger_sequence', 'idempotency_key', 'client_id', 'request_fingerprint'],
            'bazar_items' => ['receipt_url'],
            'users' => ['must_change_password'],
        ] as $table => $requiredColumns) {
            $available = self::columnNames($db, $table);
            $missing = array_values(array_diff($requiredColumns, $available));
            if ($missing !== []) {
                throw new \RuntimeException(
                    "Database migration history does not match {$table}; missing columns: " . implode(', ', $missing)
                );
            }
        }
    }

    /** @return list<string> */
    private static function columnNames(PDO $db, string $table): array
    {
        if ($db->getAttribute(PDO::ATTR_DRIVER_NAME) === 'mysql') {
            $statement = $db->prepare(
                'select column_name from information_schema.columns where table_schema = database() and table_name = :table_name'
            );
            $statement->execute(['table_name' => $table]);
            return array_map('strval', $statement->fetchAll(PDO::FETCH_COLUMN));
        }
        return array_map(
            static fn (array $row): string => (string)$row['name'],
            $db->query("pragma table_info({$table})")->fetchAll(PDO::FETCH_ASSOC)
        );
    }

    /**
     * Kept for setup reporting and backwards compatibility.
     *
     * @return list<string>
     */
    public static function statements(): array
    {
        return array_merge(...array_map(
            static fn (array $migration): array => $migration['statements'],
            self::migrations()
        ));
    }

    /** @return array<int, array{name: string, statements: list<string>}> */
    public static function migrations(): array
    {
        return [
            1 => [
                'name' => 'initial_financial_schema',
                'statements' => self::initialSchema(),
            ],
            2 => [
                'name' => 'financial_integrity_indexes',
                'statements' => self::financialIndexes(),
            ],
            3 => [
                'name' => 'api_rate_limits',
                'statements' => [
                    "create table if not exists api_rate_limits (
                        id varchar(36) primary key,
                        bucket_key varchar(64) not null,
                        window_start integer not null,
                        request_count integer not null default 0,
                        unique (bucket_key, window_start)
                    )",
                    'create index if not exists idx_api_rate_limits_window on api_rate_limits (window_start)',
                ],
            ],
            4 => [
                'name' => 'bazar_item_receipts',
                'statements' => [
                    'alter table bazar_items add column receipt_url text null',
                ],
            ],
            5 => [
                'name' => 'ledger_balance_snapshots',
                'statements' => [
                    'alter table ledger_entries add column balance_before numeric(12,2) null',
                    'alter table ledger_entries add column balance_after numeric(12,2) null',
                    'alter table ledger_entries add column reverses_ledger_entry_id varchar(36) null',
                    'alter table ledger_entries add column ledger_sequence integer null',
                    'create index if not exists idx_ledger_account_created on ledger_entries (account_id, created_at, id)',
                    'create unique index if not exists uq_ledger_account_sequence on ledger_entries (account_id, ledger_sequence)',
                    'create unique index if not exists uq_ledger_reversal on ledger_entries (reverses_ledger_entry_id)',
                ],
            ],
            6 => [
                'name' => 'ledger_reversal_idempotency',
                'statements' => [
                    'alter table ledger_entries add column idempotency_key varchar(120) null',
                    'alter table ledger_entries add column client_id varchar(120) null',
                    'alter table ledger_entries add column request_fingerprint varchar(64) null',
                    'create unique index if not exists uq_ledger_idempotency on ledger_entries (company_id, created_by, client_id, idempotency_key)',
                ],
            ],
            7 => [
                'name' => 'account_password_lifecycle',
                'statements' => [
                    'alter table users add column must_change_password integer not null default 0',
                ],
            ],
        ];
    }

    /** @return list<string> */
    private static function initialSchema(): array
    {
        return [
            "create table if not exists companies (
                id varchar(36) primary key,
                name varchar(190) not null,
                created_at datetime not null,
                updated_at datetime not null
            )",
            "create table if not exists users (
                id varchar(36) primary key,
                company_id varchar(36) not null,
                role varchar(20) not null check (role in ('admin', 'owner', 'assistant')),
                name varchar(190) not null,
                phone varchar(50),
                email varchar(190),
                password_hash varchar(255),
                is_active integer not null default 1 check (is_active in (0, 1)),
                created_at datetime not null,
                updated_at datetime not null,
                deleted_at datetime null,
                foreign key (company_id) references companies(id)
            )",
            "create table if not exists api_tokens (
                id varchar(36) primary key,
                token varchar(64) not null unique,
                user_id varchar(36) not null,
                client_id varchar(120),
                created_at datetime not null,
                last_used_at datetime null,
                revoked_at datetime null,
                foreign key (user_id) references users(id)
            )",
            "create table if not exists funds (
                id varchar(36) primary key,
                company_id varchar(36) not null,
                name varchar(190) not null,
                type varchar(50) not null default 'office_bazar',
                status varchar(20) not null default 'active' check (status in ('active', 'inactive')),
                created_by varchar(36),
                created_at datetime not null,
                updated_at datetime not null,
                deactivated_at datetime null,
                foreign key (company_id) references companies(id),
                foreign key (created_by) references users(id)
            )",
            "create table if not exists fund_managers (
                id varchar(36) primary key,
                company_id varchar(36) not null,
                fund_id varchar(36) not null,
                user_id varchar(36) not null,
                can_give_money integer not null default 1 check (can_give_money in (0, 1)),
                can_confirm_return integer not null default 1 check (can_confirm_return in (0, 1)),
                can_view_reports integer not null default 1 check (can_view_reports in (0, 1)),
                created_at datetime not null,
                unique (fund_id, user_id),
                foreign key (company_id) references companies(id),
                foreign key (fund_id) references funds(id),
                foreign key (user_id) references users(id)
            )",
            "create table if not exists fund_assistant_accounts (
                id varchar(36) primary key,
                company_id varchar(36) not null,
                fund_id varchar(36) not null,
                assistant_id varchar(36) not null,
                status varchar(20) not null default 'active' check (status in ('active', 'closed')),
                current_balance numeric(12,2) not null default 0,
                created_at datetime not null,
                updated_at datetime not null,
                closed_at datetime null,
                unique (fund_id, assistant_id),
                foreign key (company_id) references companies(id),
                foreign key (fund_id) references funds(id),
                foreign key (assistant_id) references users(id)
            )",
            "create table if not exists bazars (
                id varchar(36) primary key,
                company_id varchar(36) not null,
                fund_id varchar(36) not null,
                account_id varchar(36),
                title varchar(190) not null,
                assigned_to varchar(36),
                bazar_date date not null,
                status varchar(20) not null default 'draft' check (status in ('draft', 'open', 'closed', 'cancelled')),
                created_by varchar(36) not null,
                created_at datetime not null,
                updated_at datetime not null,
                closed_at datetime null,
                foreign key (company_id) references companies(id),
                foreign key (fund_id) references funds(id),
                foreign key (account_id) references fund_assistant_accounts(id),
                foreign key (assigned_to) references users(id),
                foreign key (created_by) references users(id)
            )",
            "create table if not exists bazar_items (
                id varchar(36) primary key,
                bazar_id varchar(36) not null,
                name varchar(190) not null,
                quantity varchar(100),
                price numeric(12,2) check (price is null or price >= 0),
                status varchar(20) not null default 'pending' check (status in ('pending', 'done', 'not_found', 'cancelled')),
                note text,
                created_at datetime not null,
                updated_at datetime not null,
                foreign key (bazar_id) references bazars(id)
            )",
            "create table if not exists ledger_entries (
                id varchar(36) primary key,
                company_id varchar(36) not null,
                fund_id varchar(36) not null,
                account_id varchar(36) not null,
                type varchar(40) not null check (type in ('fund_gave_money', 'assistant_return_confirmed', 'bazar_spend', 'adjustment')),
                amount numeric(12,2) not null check (amount > 0),
                signed_amount numeric(12,2) not null,
                source_type varchar(40) not null,
                source_id varchar(36),
                created_by varchar(36) not null,
                paid_by varchar(36),
                paid_to varchar(36),
                returned_by varchar(36),
                received_by varchar(36),
                note text,
                entry_date date not null,
                created_at datetime not null,
                voided_at datetime null,
                voided_by varchar(36),
                void_reason text,
                foreign key (company_id) references companies(id),
                foreign key (fund_id) references funds(id),
                foreign key (account_id) references fund_assistant_accounts(id),
                foreign key (created_by) references users(id)
            )",
            "create table if not exists money_entries (
                id varchar(36) primary key,
                company_id varchar(36) not null,
                fund_id varchar(36) not null,
                account_id varchar(36) not null,
                type varchar(40) not null check (type in ('fund_gave_money', 'adjustment')),
                amount numeric(12,2) not null check (amount > 0),
                signed_amount numeric(12,2) not null,
                note text,
                entry_date date not null,
                created_by varchar(36) not null,
                created_at datetime not null,
                updated_at datetime not null,
                deleted_at datetime null,
                idempotency_key varchar(120),
                client_id varchar(120),
                request_fingerprint varchar(64),
                foreign key (company_id) references companies(id),
                foreign key (fund_id) references funds(id),
                foreign key (account_id) references fund_assistant_accounts(id),
                foreign key (created_by) references users(id)
            )",
            "create table if not exists money_return_requests (
                id varchar(36) primary key,
                company_id varchar(36) not null,
                fund_id varchar(36) not null,
                account_id varchar(36) not null,
                assistant_id varchar(36) not null,
                amount numeric(12,2) not null check (amount > 0),
                note text,
                requested_by varchar(36) not null,
                expected_receiver_id varchar(36),
                status varchar(20) not null default 'pending' check (status in ('pending', 'confirmed', 'rejected')),
                requested_at datetime not null,
                confirmed_by varchar(36),
                confirmed_at datetime null,
                rejected_by varchar(36),
                rejected_at datetime null,
                rejection_reason text,
                ledger_entry_id varchar(36),
                idempotency_key varchar(120),
                client_id varchar(120),
                request_fingerprint varchar(64),
                foreign key (company_id) references companies(id),
                foreign key (fund_id) references funds(id),
                foreign key (account_id) references fund_assistant_accounts(id),
                foreign key (assistant_id) references users(id),
                foreign key (requested_by) references users(id),
                foreign key (ledger_entry_id) references ledger_entries(id)
            )",
        ];
    }

    /** @return list<string> */
    private static function financialIndexes(): array
    {
        return [
            'create index if not exists idx_api_tokens_user on api_tokens (user_id)',
            'create index if not exists idx_fund_managers_user on fund_managers (user_id, fund_id)',
            'create index if not exists idx_accounts_fund_assistant on fund_assistant_accounts (fund_id, assistant_id)',
            'create index if not exists idx_bazars_account_status on bazars (account_id, status)',
            'create index if not exists idx_bazar_items_bazar_status on bazar_items (bazar_id, status)',
            'create index if not exists idx_ledger_account_date on ledger_entries (account_id, entry_date)',
            'create unique index if not exists uq_ledger_source_type on ledger_entries (source_type, source_id, type)',
            'create unique index if not exists uq_money_idempotency on money_entries (company_id, created_by, client_id, idempotency_key)',
            'create unique index if not exists uq_return_idempotency on money_return_requests (company_id, requested_by, client_id, idempotency_key)',
            'create unique index if not exists uq_return_ledger on money_return_requests (ledger_entry_id)',
            'create index if not exists idx_returns_account_status on money_return_requests (account_id, status)',
        ];
    }
}
