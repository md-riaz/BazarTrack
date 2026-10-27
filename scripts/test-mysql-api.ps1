[CmdletBinding()]
param(
    [switch]$KeepContainers,
    [switch]$KeepArtifacts
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSScriptRoot
$runId = [Guid]::NewGuid().ToString('N')
$suffix = $runId.Substring(0, 12)
$network = "bazartrack-stage-$suffix"
$mysql = "bazartrack-mysql-$suffix"
$api = "bazartrack-api-$suffix"
$restoreMysql = "bazartrack-mysql-restore-$suffix"
$image = "bazartrack-php-mysql:$suffix"
$dbName = 'bazartrack_stage'
$dbUser = 'bazartrack'
$dbPassword = 'bazartrack-stage-password'
$rootPassword = 'bazartrack-root-password'
$runRoot = Join-Path $repoRoot ".tmp\mysql-harness\$runId"
$dumpPath = Join-Path $runRoot 'bazartrack-stage.sql'

function Invoke-MySql {
    param([Parameter(Mandatory)][string]$Sql, [string]$Database = $dbName)
    $arguments = @('exec', '-e', "MYSQL_PWD=$rootPassword", $mysql, 'mysql', '-h127.0.0.1', '-uroot', '--batch', '--skip-column-names')
    if ($Database) { $arguments += $Database }
    $arguments += @('-e', $Sql)
    for ($attempt = 1; $attempt -le 5; $attempt++) {
        $output = & docker @arguments 2>&1
        if ($LASTEXITCODE -eq 0) { return ($output -join "`n").Trim() }
        $message = ($output -join "`n")
        $transient = $message -match '(?i)unable to upgrade to tcp|received 404|is not running|connection refused|server has gone away'
        if (-not $transient -or $attempt -eq 5) {
            throw "MySQL statement failed after $attempt attempt(s): $Sql`n$message"
        }
        Start-Sleep -Seconds ([Math]::Min(2 * $attempt, 8))
    }
    throw "MySQL statement failed: $Sql"
}

function Wait-Healthy {
    param([string]$Container, [int]$Seconds = 240)
    $deadline = (Get-Date).AddSeconds($Seconds)
    do {
        $status = (& docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' $Container 2>$null | Out-String).Trim()
        if ($status -eq 'healthy') { return }
        Start-Sleep 2
    } while ((Get-Date) -lt $deadline)
    throw "$Container failed to become ready"
}

function Invoke-ApiAcceptance {
    & docker run --rm --network $network -e 'API_BASE_URL=http://api:8080/index.php' $image php api/tests/mysql_acceptance.php
    if ($LASTEXITCODE -ne 0) { throw 'MySQL API acceptance failed.' }
}

function Invoke-SetupMigration {
    & docker run --rm --network $network $image php -r "`$c=stream_context_create(['http'=>['method'=>'POST','header'=>'Content-Type: application/json','content'=>'{}','ignore_errors'=>true]]);`$r=file_get_contents('http://api:8080/index.php?cmd=setup&action=seedDemo',false,`$c);`$d=json_decode(`$r,true);if(isset(`$d['error'])){fwrite(STDERR,`$r);exit(1);}echo `$r;"
    if ($LASTEXITCODE -ne 0) { throw 'MySQL setup/migration request failed.' }
}

try {
    New-Item $runRoot -ItemType Directory -Force | Out-Null
    Write-Host "MySQL harness run id: $runId"
    & docker network create $network | Out-Null
    & docker build -f api/Dockerfile.mysql-test -t $image api
    if ($LASTEXITCODE -ne 0) { throw 'Failed to build PHP MySQL verification image.' }

    & docker run -d --name $mysql --network $network --network-alias mysql `
        -e "MYSQL_ROOT_PASSWORD=$rootPassword" -e "MYSQL_DATABASE=$dbName" `
        -e "MYSQL_USER=$dbUser" -e "MYSQL_PASSWORD=$dbPassword" `
        --health-cmd "mysqladmin ping -h127.0.0.1 -uroot -p$rootPassword --silent" `
        --health-interval 2s --health-timeout 5s --health-retries 90 mysql:8.4 | Out-Null
    Wait-Healthy $mysql
    $version = Invoke-MySql 'select version()' ''
    if (-not $version.StartsWith('8.')) { throw "Expected MySQL 8, got $version" }
    Write-Host "[PASS] MySQL server version $version" -ForegroundColor Green

    & docker run -d --name $api --network $network --network-alias api `
        -e DB_DRIVER=mysql -e DB_HOST=mysql -e DB_PORT=3306 -e "DB_DATABASE=$dbName" `
        -e "DB_USER=$dbUser" -e "DB_PASSWORD=$dbPassword" -e APP_ENV=development `
        -e DEMO_MODE=true -e INITIAL_ADMIN_PASSWORD=demo-pass -e PHP_CLI_SERVER_WORKERS=4 `
        $image php -S 0.0.0.0:8080 -t api | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Failed to start PHP API container.' }
    Start-Sleep 3

    Invoke-ApiAcceptance
    $migrationCount = [int](Invoke-MySql 'select count(*) from schema_migrations')
    Invoke-SetupMigration | Out-Null
    $migrationCountAfter = [int](Invoke-MySql 'select count(*) from schema_migrations')
    if ($migrationCountAfter -ne $migrationCount) { throw 'Migration rerun changed history unexpectedly.' }
    Write-Host '[PASS] Fresh migrations and rerun are stable' -ForegroundColor Green

    Invoke-MySql "delete from schema_migrations where version=3; drop index idx_api_rate_limits_window on api_rate_limits;"
    Invoke-SetupMigration | Out-Null
    $restored = [int](Invoke-MySql "select count(*) from information_schema.statistics where table_schema=database() and index_name='idx_api_rate_limits_window'")
    if ($restored -lt 1) { throw 'Interrupted index migration did not recover.' }
    Write-Host '[PASS] Interrupted MySQL index migration recovers on rerun' -ForegroundColor Green

    Invoke-MySql "delete from money_return_requests; delete from ledger_entries; delete from money_entries; update fund_assistant_accounts set current_balance=0 where id='acc1';"
    $token = (& docker run --rm --network $network $image php api/tests/mysql_concurrency.php | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $token.Length -ne 64) { throw "Concurrency login failed: $token" }
    $jobs = 1..2 | ForEach-Object { Start-Job -ScriptBlock { param($Network,$Image,$Token); docker run --rm --network $Network -e "TOKEN=$Token" $Image php api/tests/mysql_race_request.php } -ArgumentList $network,$image,$token }
    $raceResults = $jobs | Receive-Job -Wait -AutoRemoveJob
    $responses = @($raceResults | Where-Object { $_ -is [string] -and $_.Trim().StartsWith('{') })
    if ($responses.Count -ne 2) { throw "Expected two concurrent JSON responses: $($raceResults | ConvertTo-Json -Compress)" }
    foreach ($result in $responses) {
        $parsed = $result | ConvertFrom-Json
        $propertyNames = @((Get-Member -InputObject $parsed -MemberType NoteProperty).Name)
        if ($propertyNames -contains 'error') { throw "Concurrent request failed: $result" }
        if ($propertyNames -notcontains 'data') { throw "Concurrent response missing data: $result" }
    }
    $balance = [double](Invoke-MySql "select current_balance from fund_assistant_accounts where id='acc1'")
    $entries = [int](Invoke-MySql "select count(*) from money_entries where idempotency_key='mysql-concurrent-same'")
    if ($balance -ne 100 -or $entries -ne 1) { throw "Concurrent idempotency failed: balance=$balance entries=$entries" }
    Write-Host '[PASS] Concurrent MySQL financial calls apply exactly once' -ForegroundColor Green

    $dump = & docker exec -e "MYSQL_PWD=$rootPassword" $mysql mysqldump '--host=127.0.0.1' '--user=root' `
        --single-transaction --routines --triggers --set-gtid-purged=OFF $dbName
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace(($dump -join "`n"))) { throw 'mysqldump failed or produced an empty backup.' }
    [IO.File]::WriteAllLines($dumpPath, [string[]]$dump, [Text.UTF8Encoding]::new($false))
    Write-Host "[PASS] MySQL transactional backup created at $dumpPath" -ForegroundColor Green

    & docker run -d --name $restoreMysql --network $network --network-alias mysql-restore `
        -e "MYSQL_ROOT_PASSWORD=$rootPassword" -e "MYSQL_DATABASE=$dbName" `
        --health-cmd "mysqladmin ping -h127.0.0.1 -uroot -p$rootPassword --silent" `
        --health-interval 2s --health-timeout 5s --health-retries 90 mysql:8.4 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Failed to start restore MySQL container.' }
    Wait-Healthy $restoreMysql
    & docker cp $dumpPath "${restoreMysql}:/tmp/bazartrack-stage.sql" | Out-Null
    & docker exec -e "MYSQL_PWD=$rootPassword" $restoreMysql sh -c "mysql --host=127.0.0.1 --user=root $dbName < /tmp/bazartrack-stage.sql"
    if ($LASTEXITCODE -ne 0) { throw 'MySQL backup restore failed.' }

    $restoreQuery = { param($Sql)
        $output = & docker exec -e "MYSQL_PWD=$rootPassword" $restoreMysql mysql '--host=127.0.0.1' '--user=root' --batch --skip-column-names $dbName -e $Sql 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Restore verification query failed: $Sql" }
        return ($output -join "`n").Trim()
    }
    $restoredMigrationCount = [int](& $restoreQuery 'select count(*) from schema_migrations')
    $sourceMigrationCount = [int](Invoke-MySql 'select count(*) from schema_migrations')
    if ($restoredMigrationCount -ne $sourceMigrationCount) { throw "Restored migration history mismatch: source=$sourceMigrationCount restored=$restoredMigrationCount" }
    $restoredBalance = [double](& $restoreQuery "select current_balance from fund_assistant_accounts where id='acc1'")
    $restoredLedgerBalance = [double](& $restoreQuery "select coalesce(sum(signed_amount),0) from ledger_entries where account_id='acc1' and voided_at is null")
    $restoredEntryCount = [int](& $restoreQuery "select count(*) from money_entries where idempotency_key='mysql-concurrent-same'")
    if ($restoredBalance -ne $restoredLedgerBalance -or $restoredBalance -ne 100 -or $restoredEntryCount -ne 1) {
        throw "Restored financial state mismatch: stored=$restoredBalance ledger=$restoredLedgerBalance entries=$restoredEntryCount"
    }
    Write-Host '[PASS] Backup restores into a fresh MySQL 8 instance with migration history and reconciled ledger intact' -ForegroundColor Green

    Write-Host 'MySQL 8 staging verification passed; independent review is still required.' -ForegroundColor Cyan
} finally {
    if ($KeepArtifacts) {
        try { docker logs $mysql *> (Join-Path $runRoot 'mysql.log') } catch {}
        try { docker logs $api *> (Join-Path $runRoot 'api.log') } catch {}
        try { docker logs $restoreMysql *> (Join-Path $runRoot 'mysql-restore.log') } catch {}
    }
    if (-not $KeepContainers) {
        $existing = @(& docker ps -a --format '{{.Names}}')
        foreach ($container in @($api, $mysql, $restoreMysql)) {
            if ($existing -contains $container) { & docker rm -f $container | Out-Null }
        }
        & docker network rm $network 2>$null | Out-Null
        $images = @(& docker images --format '{{.Repository}}:{{.Tag}}')
        if ($images -contains $image) { & docker image rm $image | Out-Null }
    }
}
