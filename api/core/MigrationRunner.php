<?php

declare(strict_types=1);

namespace Core;

use PDO;
use Throwable;

final class MigrationRunner
{
    /**
     * @param array<int, array{name: string, statements: list<string>}> $migrations
     */
    public static function migrate(PDO $db, array $migrations): void
    {
        self::assertSafeBaseline($db);
        self::ensureHistoryTable($db);
        $applied = self::appliedVersions($db);

        foreach ($migrations as $version => $migration) {
            if (isset($applied[$version])) {
                continue;
            }

            // SQLite supports transactional DDL. MySQL commits DDL implicitly, but
            // each MySQL 8 DDL statement is atomic and the migration is recorded only
            // after every statement succeeds.
            $transactionalDdl = $db->getAttribute(PDO::ATTR_DRIVER_NAME) !== 'mysql';
            if ($transactionalDdl) {
                $db->beginTransaction();
            }
            try {
                foreach ($migration['statements'] as $statement) {
                    if (self::shouldSkipExistingIndex($db, $statement)
                        || self::shouldSkipExistingColumn($db, $statement)) {
                        continue;
                    }
                    $db->exec(self::forDriver($db, $statement));
                }
                $insert = $db->prepare(
                    'insert into schema_migrations (version, name, applied_at) values (:version, :name, :applied_at)'
                );
                $insert->execute([
                    'version' => $version,
                    'name' => $migration['name'],
                    'applied_at' => gmdate('Y-m-d H:i:s'),
                ]);
                if ($transactionalDdl) {
                    $db->commit();
                }
            } catch (Throwable $error) {
                if ($transactionalDdl && $db->inTransaction()) {
                    $db->rollBack();
                }
                throw $error;
            }
        }
    }

    private static function assertSafeBaseline(PDO $db): void
    {
        if (self::tableExists($db, 'schema_migrations') || !self::tableExists($db, 'companies')) {
            return;
        }
        throw new \RuntimeException(
            'Legacy database detected without schema_migrations. Refusing to mark it migrated because existing tables lack enforceable production constraints. Back up and import into a freshly migrated database.'
        );
    }

    private static function ensureHistoryTable(PDO $db): void
    {
        $db->exec(
            'create table if not exists schema_migrations (
                version integer primary key,
                name varchar(190) not null,
                applied_at datetime not null
            )'
        );
    }

    private static function tableExists(PDO $db, string $table): bool
    {
        if ($db->getAttribute(PDO::ATTR_DRIVER_NAME) === 'mysql') {
            $statement = $db->prepare(
                'select count(*) from information_schema.tables where table_schema = database() and table_name = :table_name'
            );
            $statement->execute(['table_name' => $table]);
            return (int)$statement->fetchColumn() > 0;
        }
        $statement = $db->prepare("select count(*) from sqlite_master where type = 'table' and name = :table_name");
        $statement->execute(['table_name' => $table]);
        return (int)$statement->fetchColumn() > 0;
    }

    private static function forDriver(PDO $db, string $statement): string
    {
        if ($db->getAttribute(PDO::ATTR_DRIVER_NAME) === 'mysql') {
            return str_replace(
                ['create unique index if not exists ', 'create index if not exists '],
                ['create unique index ', 'create index '],
                $statement
            );
        }
        return $statement;
    }

    private static function shouldSkipExistingIndex(PDO $db, string $statement): bool
    {
        if ($db->getAttribute(PDO::ATTR_DRIVER_NAME) !== 'mysql') {
            return false;
        }
        if (preg_match('/^create (?:unique )?index if not exists ([a-zA-Z0-9_]+)/i', trim($statement), $match) !== 1) {
            return false;
        }
        $check = $db->prepare(
            'select count(*) from information_schema.statistics where table_schema = database() and index_name = :index_name'
        );
        $check->execute(['index_name' => $match[1]]);
        return (int)$check->fetchColumn() > 0;
    }

    private static function shouldSkipExistingColumn(PDO $db, string $statement): bool
    {
        if (preg_match('/^alter table ([a-zA-Z0-9_]+) add column ([a-zA-Z0-9_]+)/i', trim($statement), $match) !== 1) {
            return false;
        }
        if ($db->getAttribute(PDO::ATTR_DRIVER_NAME) === 'mysql') {
            $check = $db->prepare(
                'select count(*) from information_schema.columns where table_schema = database() and table_name = :table_name and column_name = :column_name'
            );
            $check->execute(['table_name' => $match[1], 'column_name' => $match[2]]);
            return (int)$check->fetchColumn() > 0;
        }
        $columns = $db->query("pragma table_info({$match[1]})")->fetchAll(PDO::FETCH_ASSOC);
        return in_array($match[2], array_column($columns, 'name'), true);
    }

    /** @return array<int, true> */
    private static function appliedVersions(PDO $db): array
    {
        $versions = [];
        $result = $db->query('select version from schema_migrations order by version');
        foreach ($result->fetchAll(PDO::FETCH_COLUMN) as $version) {
            $versions[(int)$version] = true;
        }
        return $versions;
    }
}
