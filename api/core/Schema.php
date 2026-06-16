<?php

declare(strict_types=1);

namespace Core;

use PDO;

final class Schema
{
    public static function migrate(PDO $db): void
    {
        foreach (self::statements() as $sql) {
            $db->exec($sql);
        }
    }

    public static function statements(): array
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
                role varchar(20) not null,
                name varchar(190) not null,
                phone varchar(50),
                email varchar(190),
                password_hash varchar(255),
                is_active integer not null default 1,
                created_at datetime not null,
                updated_at datetime not null,
                deleted_at datetime null
            )",
            "create table if not exists funds (
                id varchar(36) primary key,
                company_id varchar(36) not null,
                name varchar(190) not null,
                type varchar(50) not null default 'office_bazar',
                status varchar(20) not null default 'active',
                created_by varchar(36),
                created_at datetime not null,
                updated_at datetime not null,
                deactivated_at datetime null
            )",
            "create table if not exists fund_managers (
                id varchar(36) primary key,
                company_id varchar(36) not null,
                fund_id varchar(36) not null,
                user_id varchar(36) not null,
                can_give_money integer not null default 1,
                can_confirm_return integer not null default 1,
                can_view_reports integer not null default 1,
                created_at datetime not null
            )",
            "create table if not exists fund_assistant_accounts (
                id varchar(36) primary key,
                company_id varchar(36) not null,
                fund_id varchar(36) not null,
                assistant_id varchar(36) not null,
                status varchar(20) not null default 'active',
                current_balance numeric(12,2) not null default 0,
                created_at datetime not null,
                updated_at datetime not null,
                closed_at datetime null
            )",
            "create table if not exists bazars (
                id varchar(36) primary key,
                company_id varchar(36) not null,
                fund_id varchar(36) not null,
                account_id varchar(36),
                title varchar(190) not null,
                assigned_to varchar(36),
                bazar_date date not null,
                status varchar(20) not null default 'draft',
                created_by varchar(36) not null,
                created_at datetime not null,
                updated_at datetime not null,
                closed_at datetime null
            )",
            "create table if not exists bazar_items (
                id varchar(36) primary key,
                bazar_id varchar(36) not null,
                name varchar(190) not null,
                quantity varchar(100),
                price numeric(12,2),
                status varchar(20) not null default 'pending',
                note text,
                created_at datetime not null,
                updated_at datetime not null
            )",
            "create table if not exists ledger_entries (
                id varchar(36) primary key,
                company_id varchar(36) not null,
                fund_id varchar(36) not null,
                account_id varchar(36) not null,
                type varchar(40) not null,
                amount numeric(12,2) not null,
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
                void_reason text
            )",
            "create table if not exists money_entries (
                id varchar(36) primary key,
                company_id varchar(36) not null,
                fund_id varchar(36) not null,
                account_id varchar(36) not null,
                type varchar(40) not null,
                amount numeric(12,2) not null,
                signed_amount numeric(12,2) not null,
                note text,
                entry_date date not null,
                created_by varchar(36) not null,
                created_at datetime not null,
                updated_at datetime not null,
                deleted_at datetime null,
                idempotency_key varchar(120)
            )",
            "create table if not exists money_return_requests (
                id varchar(36) primary key,
                company_id varchar(36) not null,
                fund_id varchar(36) not null,
                account_id varchar(36) not null,
                assistant_id varchar(36) not null,
                amount numeric(12,2) not null,
                note text,
                requested_by varchar(36) not null,
                expected_receiver_id varchar(36),
                status varchar(20) not null default 'pending',
                requested_at datetime not null,
                confirmed_by varchar(36),
                confirmed_at datetime null,
                rejected_by varchar(36),
                rejected_at datetime null,
                rejection_reason text,
                ledger_entry_id varchar(36),
                idempotency_key varchar(120)
            )"
        ];
    }
}
