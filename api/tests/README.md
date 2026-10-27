# Local API acceptance harness

Run the PHP API against a fresh, isolated SQLite database:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-local-api.ps1
```

The strict/default mode is the production-readiness gate. It expects protected endpoints to reject missing credentials, enforces role/object boundaries, verifies token revocation, and checks financial replay/invariant behavior.

`-CompatibilityMode` is explicitly non-release diagnostics only. It exercises the financial journey but may record legacy permission gaps as skips and must never be used as deployment evidence:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-local-api.ps1 -CompatibilityMode
```

Use a different port when `18080` is occupied:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-local-api.ps1 -Port 18081
```

The harness:

1. Creates a unique `.tmp/api-harness/<run-id>/` directory, sets `DB_DRIVER=sqlite`, and points `SQLITE_PATH` at that run's isolated database.
2. Starts `php -S 127.0.0.1:<port> -t api`.
3. Waits for the health endpoint.
4. Runs `setup/seedDemo` in development/demo mode.
5. Logs in as Admin, Fund Manager, and Assistant.
6. Checks `auth/me`, logout/revocation, malformed/unknown tokens, role boundaries, actor spoofing, and unmanaged-fund isolation.
7. Gives money with an idempotency replay and rejects assistant access.
8. Creates and closes an assigned bazar, then verifies close replay does not double-spend.
9. Rejects excessive returns, creates a valid return request, blocks assistant confirmation, and confirms it separately as Fund Manager.
10. Reconciles the final account balance with the report.
11. Runs the opt-in Flutter/API response contract tests against that same server.
12. Stops the PHP process in a `finally` block and removes temporary artifacts.

Use `-SkipFlutterContract` only for a quick API-only diagnostic run.

Pass `-KeepArtifacts` to retain the isolated database and PHP logs after a run.

The harness intentionally does not use `api/storage/dev.sqlite`; local developer data is never modified.

## Existing databases

The numbered migration runner intentionally refuses an existing unversioned/legacy database. `CREATE TABLE IF NOT EXISTS` cannot retrofit its missing foreign keys and checks safely, so recording migration versions would create a false production-ready state. Before upgrading:

1. Stop writes and take a verified backup.
2. Export the legacy business data.
3. Create a fresh database and run the current numbered migrations.
4. Import through a reviewed transformation that satisfies current constraints.
5. Run reconciliation and the full acceptance harness before cutover.

Do not manually insert rows into `schema_migrations` to bypass this refusal.

## External release gate

SQLite is the deterministic local/demo verification database. Run the isolated Docker MySQL 8 staging gate with:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-mysql-api.ps1 -KeepArtifacts
```

The gate builds a PHP 8.3 + `pdo_mysql` verification image, starts MySQL 8 on an isolated Docker network, exercises the API journey, reruns migrations, simulates an interrupted index migration, and sends concurrent same-key financial calls to prove they apply once. It then creates a transactional `mysqldump`, restores it into a fresh MySQL 8 container, and verifies migration history plus stored/ledger balance reconciliation. `-KeepArtifacts` saves the SQL backup and container logs under `.tmp/mysql-harness/<run-id>/`; `-KeepContainers` preserves containers for diagnosis.

A successful local run is required evidence, not production approval. Deployment still requires independent review and operational rehearsal in the target environment.
