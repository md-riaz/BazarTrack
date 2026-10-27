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

$fresh = new PDO('sqlite::memory:');
$fresh->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
Schema::migrate($fresh);
Schema::migrate($fresh);
$versions = $fresh->query('select count(*) from schema_migrations')->fetchColumn();
check((int)$versions === count(Schema::migrations()), 'fresh migrations are recorded exactly once and rerun safely');

$columns = $fresh->query('pragma table_info(money_entries)')->fetchAll(PDO::FETCH_ASSOC);
$columnNames = array_column($columns, 'name');
check(in_array('client_id', $columnNames, true), 'money idempotency client scope exists');
check(in_array('request_fingerprint', $columnNames, true), 'money request fingerprint exists');

$legacy = new PDO('sqlite::memory:');
$legacy->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
$legacy->exec('create table companies (id varchar(36) primary key)');
try {
    Schema::migrate($legacy);
    throw new RuntimeException('legacy database was incorrectly marked migrated');
} catch (RuntimeException $error) {
    check(str_contains($error->getMessage(), 'Legacy database detected'), 'legacy schema fails safely instead of recording false versions');
}

$falseHistory = new PDO('sqlite::memory:');
$falseHistory->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
$falseHistory->exec('create table schema_migrations (version integer primary key, name varchar(190), applied_at datetime)');
$falseHistory->exec("insert into schema_migrations values (1, 'initial_financial_schema', '2026-01-01')");
$falseHistory->exec("insert into schema_migrations values (2, 'financial_integrity_indexes', '2026-01-01')");
$falseHistory->exec("insert into schema_migrations values (3, 'api_rate_limits', '2026-01-01')");
$falseHistory->exec('create table money_entries (id varchar(36) primary key)');
$falseHistory->exec('create table money_return_requests (id varchar(36) primary key)');
try {
    Schema::migrate($falseHistory);
    throw new RuntimeException('false migration history was incorrectly accepted');
} catch (RuntimeException $error) {
    check(str_contains($error->getMessage(), 'does not match'), 'false migration history fails schema verification');
}

$lockPath = tempnam(sys_get_temp_dir(), 'bazar-fin-lock-');
try {
    $writerOne = new PDO('sqlite:' . $lockPath);
    $writerTwo = new PDO('sqlite:' . $lockPath);
    foreach ([$writerOne, $writerTwo] as $writer) {
        $writer->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $writer->exec('pragma busy_timeout = 100');
    }
    $writerOne->exec('create table serialized_writes (id integer primary key, value integer not null)');
    $writerOne->exec('begin immediate');
    $writerOne->exec('insert into serialized_writes (id, value) values (1, 1)');
    $locked = false;
    try {
        $writerTwo->exec('begin immediate');
    } catch (PDOException $error) {
        $locked = str_contains(strtolower($error->getMessage()), 'locked');
    }
    check($locked, 'SQLite BEGIN IMMEDIATE serializes competing financial writers');
    $writerOne->exec('commit');
    $writerTwo->exec('begin immediate');
    $writerTwo->exec('update serialized_writes set value = value + 1 where id = 1');
    $writerTwo->exec('commit');
    check((int)$writerOne->query('select value from serialized_writes where id = 1')->fetchColumn() === 2, 'waiting writer succeeds after first transaction completes');
} finally {
    @unlink($lockPath);
}

