<?php

declare(strict_types=1);

use Core\Autoload;
use Core\Schema;

require dirname(__DIR__) . '/core/Autoload.php';
Autoload::register(dirname(__DIR__));

function check(bool $condition, string $message): void
{
    if (!$condition) {
        throw new RuntimeException($message);
    }
    echo "[PASS] {$message}\n";
}

$db = new PDO('sqlite::memory:');
$db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
Schema::migrate($db);

$columns = $db->query('pragma table_info(ledger_entries)')->fetchAll(PDO::FETCH_ASSOC);
$names = array_column($columns, 'name');
check(in_array('balance_before', $names, true), 'ledger stores balance before each change');
check(in_array('balance_after', $names, true), 'ledger stores balance after each change');
check(in_array('reverses_ledger_entry_id', $names, true), 'ledger links reversal entries to originals');
check(in_array('ledger_sequence', $names, true), 'ledger assigns a deterministic per-account sequence');

$db->exec("insert into companies (id, name, created_at, updated_at) values ('c1', 'Test', '2026-01-01', '2026-01-01')");
$db->exec("insert into users (id, company_id, role, name, is_active, created_at, updated_at) values ('u1', 'c1', 'admin', 'Admin', 1, '2026-01-01', '2026-01-01')");
$db->exec("insert into funds (id, company_id, name, created_at, updated_at) values ('f1', 'c1', 'Fund', '2026-01-01', '2026-01-01')");
$db->exec("insert into fund_assistant_accounts (id, company_id, fund_id, assistant_id, current_balance, created_at, updated_at) values ('a1', 'c1', 'f1', 'u1', 15, '2026-01-01', '2026-01-01')");

$db->exec("insert into ledger_entries (id, company_id, fund_id, account_id, type, amount, signed_amount, balance_before, balance_after, ledger_sequence, source_type, source_id, created_by, entry_date, created_at) values ('l1', 'c1', 'f1', 'a1', 'fund_gave_money', 20, 20, 0, 20, 1, 'money_entry', 'm1', 'u1', '2026-01-01', '2026-01-01')");
$db->exec("insert into ledger_entries (id, company_id, fund_id, account_id, type, amount, signed_amount, balance_before, balance_after, ledger_sequence, source_type, source_id, created_by, entry_date, created_at) values ('l2', 'c1', 'f1', 'a1', 'bazar_spend', 5, -5, 20, 15, 2, 'bazar', 'b1', 'u1', '2026-01-01', '2026-01-01')");

$last = $db->query("select balance_after from ledger_entries where account_id = 'a1' order by ledger_sequence desc limit 1")->fetchColumn();
check((float)$last === 15.0, 'ledger snapshots retain the latest balance after each transaction');
$ordered = $db->query("select id from ledger_entries where account_id = 'a1' order by ledger_sequence")->fetchAll(PDO::FETCH_COLUMN);
check($ordered === ['l1', 'l2'], 'same-timestamp entries retain the committed sequence order');
$storedBalance = $db->query("select current_balance from fund_assistant_accounts where id = 'a1'")->fetchColumn();
check((float)$storedBalance === (float)$last, 'stored account balance matches the final ledger snapshot');

$triggers = $db->query("select name from sqlite_master where type = 'trigger' and tbl_name = 'ledger_entries'")->fetchAll(PDO::FETCH_COLUMN);
check(count($triggers) >= 2, 'ledger update and delete operations are blocked by database triggers');
