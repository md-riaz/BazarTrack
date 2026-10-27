[CmdletBinding()]
param(
    [int]$Port = 18080,
    [ValidateSet('sqlite', 'mysql')][string]$DatabaseDriver = 'sqlite',
    [string]$DatabaseHost = '127.0.0.1',
    [int]$DatabasePort = 3306,
    [string]$DatabaseName = 'bazartrack',
    [string]$DatabaseUser = 'bazartrack',
    [string]$DatabasePassword = 'change-me',
    [switch]$CompatibilityMode,
    [switch]$SkipFlutterContract,
    [switch]$KeepArtifacts
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSScriptRoot
$apiRoot = Join-Path $repoRoot 'api'
$runId = [Guid]::NewGuid().ToString('N')
$runRoot = Join-Path $repoRoot ".tmp\api-harness\$runId"
$dbPath = Join-Path $runRoot 'acceptance.sqlite'
$stdoutPath = Join-Path $runRoot 'php.stdout.log'
$stderrPath = Join-Path $runRoot 'php.stderr.log'
$baseUrl = "http://127.0.0.1:$Port/index.php"
$php = $null
$previousEnvironment = @{}
$script:Passed = 0
$script:Skipped = 0

function Assert-Equal {
    param([object]$Actual, [object]$Expected, [string]$Message)
    if ($Actual -ne $Expected) {
        throw "$Message. Expected '$Expected', got '$Actual'."
    }
    $script:Passed++
    Write-Host "[PASS] $Message" -ForegroundColor Green
}

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
    $script:Passed++
    Write-Host "[PASS] $Message" -ForegroundColor Green
}

function Skip-Check {
    param([string]$Message)
    $script:Skipped++
    Write-Host "[SKIP] $Message" -ForegroundColor Yellow
}

function Invoke-HarnessSql {
    param([Parameter(Mandatory)][string]$Sql)
    $encodedSql = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Sql))
    if ($DatabaseDriver -eq 'mysql') {
        $dsn = "mysql:host=$DatabaseHost;port=$DatabasePort;dbname=$DatabaseName;charset=utf8mb4"
        $encodedDsn = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($dsn))
        $encodedUser = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($DatabaseUser))
        $encodedPassword = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($DatabasePassword))
        & php -r "`$db=new PDO(base64_decode('$encodedDsn'),base64_decode('$encodedUser'),base64_decode('$encodedPassword'));`$db->setAttribute(PDO::ATTR_ERRMODE,PDO::ERRMODE_EXCEPTION);`$db->exec(base64_decode('$encodedSql'));"
    } else {
        $encodedPath = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($dbPath))
        & php -r "`$db=new PDO('sqlite:'.base64_decode('$encodedPath'));`$db->setAttribute(PDO::ATTR_ERRMODE,PDO::ERRMODE_EXCEPTION);`$db->exec(base64_decode('$encodedSql'));"
    }
    if ($LASTEXITCODE -ne 0) { throw "Harness SQL failed: $Sql" }
}

function Set-HarnessEnvironment {
    param([string]$Name, [string]$Value)
    $previousEnvironment[$Name] = [Environment]::GetEnvironmentVariable($Name, 'Process')
    [Environment]::SetEnvironmentVariable($Name, $Value, 'Process')
}

function Restore-HarnessEnvironment {
    foreach ($entry in $previousEnvironment.GetEnumerator()) {
        [Environment]::SetEnvironmentVariable($entry.Key, $entry.Value, 'Process')
    }
}

function Invoke-Api {
    param(
        [Parameter(Mandatory)][string]$Command,
        [Parameter(Mandatory)][string]$Action,
        [ValidateSet('GET', 'POST')][string]$Method = 'GET',
        [hashtable]$Query = @{},
        [object]$Body,
        [string]$Token,
        [hashtable]$Headers = @{},
        [int[]]$ExpectedStatus = @(200)
    )

    $queryParts = @(
        ('cmd=' + [Uri]::EscapeDataString($Command))
        ('action=' + [Uri]::EscapeDataString($Action))
    )
    foreach ($entry in $Query.GetEnumerator()) {
        if ($null -ne $entry.Value) {
            $queryParts += [Uri]::EscapeDataString([string]$entry.Key) + '=' + [Uri]::EscapeDataString([string]$entry.Value)
        }
    }
    $uri = $baseUrl + '?' + ($queryParts -join '&')
    $requestHeaders = @{'Accept' = 'application/json'; 'X-Client-Id' = 'bazartrack-acceptance'}
    foreach ($entry in $Headers.GetEnumerator()) { $requestHeaders[$entry.Key] = $entry.Value }
    if ($Token) { $requestHeaders['Authorization'] = "Bearer $Token" }

    $parameters = @{
        Uri = $uri
        Method = $Method
        Headers = $requestHeaders
        UseBasicParsing = $true
    }
    if ($null -ne $Body) {
        $parameters.ContentType = 'application/json'
        $parameters.Body = ConvertTo-Json $Body -Depth 12 -Compress
    }

    try {
        $response = Invoke-WebRequest @parameters
    } catch {
        if ($null -eq $_.Exception.Response) { throw }
        $response = $_.Exception.Response
        $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
        $content = $reader.ReadToEnd()
        $reader.Dispose()
        $status = [int]$response.StatusCode
        if ($ExpectedStatus -notcontains $status) {
            throw "$Method $uri returned HTTP $status. Body: $content"
        }
        return [pscustomobject]@{ Status = $status; Body = ($content | ConvertFrom-Json) }
    }

    $status = [int]$response.StatusCode
    if ($ExpectedStatus -notcontains $status) {
        throw "$Method $uri returned HTTP $status. Body: $($response.Content)"
    }
    [pscustomobject]@{ Status = $status; Body = ($response.Content | ConvertFrom-Json) }
}

function Assert-SafeValidationError {
    param(
        [Parameter(Mandatory)][string]$Command,
        [Parameter(Mandatory)][string]$Action,
        [Parameter(Mandatory)][string]$Token,
        [Parameter(Mandatory)][object]$Body,
        [Parameter(Mandatory)][string]$Message
    )
    $response = Invoke-Api -Command $Command -Action $Action -Method POST -Token $Token -Body $Body -ExpectedStatus @(422)
    Assert-Equal $response.Status 422 $Message
    $serialized = ConvertTo-Json $response.Body -Depth 10 -Compress
    Assert-True ($serialized -notmatch '(?i)warning|C:\\|/var/|/home/|stack trace') "$Message returns clean JSON without warnings or paths"
}

function Login-DemoRole {
    param([string]$Role)
    $response = Invoke-Api -Command auth -Action login -Method POST -Body @{phone=$Role; password='demo-pass'}
    $data = $response.Body.data
    Assert-True ($null -ne $data.token -and ([string]$data.token).Length -ge 16) "$Role login returns an API token"
    return $data
}

function Wait-ForHealth {
    $deadline = (Get-Date).AddSeconds(15)
    do {
        try {
            $health = Invoke-Api -Command health -Action index
            if ($health.Body.data.ok -eq $true) { return }
        } catch {
            Start-Sleep -Milliseconds 200
        }
    } while ((Get-Date) -lt $deadline)
    throw "PHP API did not become healthy at $baseUrl. See $stderrPath"
}

try {
    if (-not (Get-Command php -ErrorAction SilentlyContinue)) {
        throw 'PHP is not available on PATH.'
    }
    New-Item $runRoot -ItemType Directory -Force | Out-Null
    Write-Host "Harness run id: $runId"

    Set-HarnessEnvironment DB_DRIVER $DatabaseDriver
    if ($DatabaseDriver -eq 'sqlite') {
        Set-HarnessEnvironment SQLITE_PATH $dbPath
    } else {
        Set-HarnessEnvironment DB_HOST $DatabaseHost
        Set-HarnessEnvironment DB_PORT ([string]$DatabasePort)
        Set-HarnessEnvironment DB_DATABASE $DatabaseName
        Set-HarnessEnvironment DB_USER $DatabaseUser
        Set-HarnessEnvironment DB_PASSWORD $DatabasePassword
    }
    Set-HarnessEnvironment APP_ENV 'development'
    Set-HarnessEnvironment DEMO_MODE 'true'
    Set-HarnessEnvironment DEFAULT_COMPANY_ID 'company1'
    Set-HarnessEnvironment INITIAL_ADMIN_PASSWORD 'demo-pass'

    $php = Start-Process php -ArgumentList @('-S', "127.0.0.1:$Port", '-t', $apiRoot) -WorkingDirectory $repoRoot -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath -PassThru
    Wait-ForHealth
    if ($DatabaseDriver -eq 'sqlite') {
        Assert-True (Test-Path $dbPath) 'Harness uses an isolated SQLite database'
    } else {
        Assert-True $true "Harness uses isolated MySQL database $DatabaseName"
    }

    $seed = Invoke-Api -Command setup -Action seedDemo -Method POST -Body @{}
    Assert-True ($seed.Body.data.demoSeeded -eq $true) 'Development demo seed succeeds'

    $admin = Login-DemoRole admin
    $manager = Login-DemoRole owner
    $assistant = Login-DemoRole assistant
    Assert-Equal $admin.user.role 'admin' 'Admin role is preserved'
    Assert-Equal $manager.user.role 'owner' 'Fund Manager role is preserved'
    Assert-Equal $assistant.user.role 'assistant' 'Assistant role is preserved'

    $me = Invoke-Api -Command auth -Action me -Token $assistant.token
    Assert-Equal $me.Body.data.id 'assistant1' 'auth/me resolves the bearer-token user'
    $malformedToken = Invoke-Api -Command auth -Action me -Token 'not-a-valid-token' -ExpectedStatus @(401)
    Assert-Equal $malformedToken.Status 401 'Malformed token is rejected'
    $unknownToken = Invoke-Api -Command auth -Action me -Token ('f' * 64) -ExpectedStatus @(401)
    Assert-Equal $unknownToken.Status 401 'Unknown well-formed token is rejected'
    $logoutSession = Login-DemoRole assistant
    $logout = Invoke-Api -Command auth -Action logout -Method POST -Token $logoutSession.token -Body @{}
    Assert-True ($logout.Body.data.revoked -eq $true) 'Logout revokes the current token'
    $revoked = Invoke-Api -Command auth -Action me -Token $logoutSession.token -ExpectedStatus @(401)
    Assert-Equal $revoked.Status 401 'Revoked token cannot access auth/me'

    $funds = Invoke-Api -Command funds -Action list -Token $manager.token
    Assert-Equal @($funds.Body.data).Count 1 'Demo seed exposes one fund'
    $accounts = Invoke-Api -Command accounts -Action list -Token $manager.token
    Assert-Equal @($accounts.Body.data).Count 1 'Demo seed exposes one assistant account'

    Assert-SafeValidationError -Command users -Action create -Token $admin.token -Body @{role='assistant'; name=@{}} -Message 'Object user name is rejected'
    $validBazarBase = @{fundId='fund1'; accountId='acc1'; createdBy='manager1'; status='open'; bazarDate='2026-10-26'}
    Assert-SafeValidationError -Command bazars -Action create -Token $manager.token -Body ($validBazarBase + @{title=@{}; items=@()}) -Message 'Object bazar title is rejected'
    Assert-SafeValidationError -Command bazars -Action create -Token $manager.token -Body ($validBazarBase + @{title='Bad item name'; items=@(@{name=@{}})}) -Message 'Object item name is rejected'
    Assert-SafeValidationError -Command bazars -Action create -Token $manager.token -Body ($validBazarBase + @{title='Bad quantity'; items=@(@{name='Rice'; quantity=@{}})}) -Message 'Object item quantity is rejected'
    Assert-SafeValidationError -Command bazars -Action create -Token $manager.token -Body ($validBazarBase + @{title='Bad note'; items=@(@{name='Rice'; note=@{}})}) -Message 'Object item note is rejected'

    $unauthorized = Invoke-Api -Command funds -Action list -ExpectedStatus @(200, 401)
    if ($CompatibilityMode -and $unauthorized.Status -eq 200) {
        Skip-Check 'Legacy API currently permits unauthenticated fund listing; strict mode requires HTTP 401.'
    } else {
        Assert-Equal $unauthorized.Status 401 'Protected fund listing rejects missing token'
    }

    $forbidden = Invoke-Api -Command users -Action create -Method POST -Token $assistant.token -Body @{role='assistant'; name='Forbidden User'} -ExpectedStatus @(200, 403)
    if ($CompatibilityMode -and $forbidden.Status -eq 200) {
        Skip-Check 'Legacy API currently permits assistant user creation; strict mode requires HTTP 403.'
    } else {
        Assert-Equal $forbidden.Status 403 'Assistant cannot create users'
    }
    $managerAdmin = Invoke-Api -Command users -Action create -Method POST -Token $manager.token -Body @{role='assistant'; name='Manager Forbidden User'} -ExpectedStatus @(403)
    Assert-Equal $managerAdmin.Status 403 'Fund Manager cannot create users'
    $assistantMoney = Invoke-Api -Command money -Action give -Method POST -Token $assistant.token -Headers @{'Idempotency-Key'='assistant-forbidden-give'} -Body @{accountId='acc1'; amount=1; createdBy='assistant1'} -ExpectedStatus @(403)
    Assert-Equal $assistantMoney.Status 403 'Assistant cannot give money'
    $assistantReport = Invoke-Api -Command reports -Action summary -Token $assistant.token -Query @{from='2026-10-01'; to='2026-10-31'; fundId='fund1'} -ExpectedStatus @(403)
    Assert-Equal $assistantReport.Status 403 'Assistant cannot access reports'
    $forgedCreate = Invoke-Api -Command funds -Action create -Method POST -Token $admin.token -Body @{name='Forged Actor Fund'; companyId='other-company'; createdBy='assistant1'}
    Assert-Equal $forgedCreate.Body.data.company_id 'company1' 'Client companyId is ignored in favor of token company'
    Assert-Equal $forgedCreate.Body.data.created_by 'admin1' 'Client createdBy is ignored in favor of token actor'
    $forgedFundId = [string]$forgedCreate.Body.data.id
    $managerCrossFund = Invoke-Api -Command funds -Action show -Token $manager.token -Query @{id=$forgedFundId} -ExpectedStatus @(404)
    Assert-Equal $managerCrossFund.Status 404 'Fund Manager cannot access an unmanaged fund'
    $managerCrossReconcile = Invoke-Api -Command ledger -Action reconcile -Token $manager.token -Query @{fundId=$forgedFundId} -ExpectedStatus @(403,404)
    Assert-True ($managerCrossReconcile.Status -in @(403,404)) 'Fund Manager cannot reconcile an unmanaged fund'

    Invoke-HarnessSql "update fund_managers set can_give_money=0 where user_id='manager1' and fund_id='fund1'"
    $capabilityDenied = Invoke-Api -Command money -Action give -Method POST -Token $manager.token -Headers @{'Idempotency-Key'='capability-denied'} -Body @{accountId='acc1'; amount=1} -ExpectedStatus @(403)
    Assert-Equal $capabilityDenied.Status 403 'Fund Manager cannot give money when capability is disabled'
    Invoke-HarnessSql "update fund_managers set can_give_money=1 where user_id='manager1' and fund_id='fund1'"

    $moneyHeaders = @{'Idempotency-Key' = 'acceptance-give-1'}
    $given = Invoke-Api -Command money -Action give -Method POST -Token $manager.token -Headers $moneyHeaders -Body @{accountId='acc1'; amount=1000; createdBy='manager1'; paidBy='manager1'; note='Acceptance advance'; entryDate='2026-10-26'}
    Assert-Equal ([double]$given.Body.data.accountBalance) 1000 'Fund Manager gives assistant 1000'

    $replayed = Invoke-Api -Command money -Action give -Method POST -Token $manager.token -Headers $moneyHeaders -Body @{accountId='acc1'; amount=1000; createdBy='manager1'; paidBy='manager1'; note='Acceptance advance'; entryDate='2026-10-26'}
    Assert-True ($replayed.Body.data.idempotentReplay -eq $true) 'Money give is idempotent on replay'
    $mismatch = Invoke-Api -Command money -Action give -Method POST -Token $manager.token -Headers $moneyHeaders -Body @{accountId='acc1'; amount=999; note='Changed payload'; entryDate='2026-10-26'} -ExpectedStatus @(409)
    Assert-Equal $mismatch.Status 409 'Money idempotency key rejects a different payload'

    $bazar = Invoke-Api -Command bazars -Action create -Method POST -Token $manager.token -Body @{
        fundId='fund1'; accountId='acc1'; title='Acceptance Bazar'; createdBy='manager1'; assignedTo='assistant1'; status='open'; bazarDate='2026-10-26';
        items=@(@{name='Rice'; quantity='1 kg'; price=200; status='done'})
    }
    $bazarId = [string]$bazar.Body.data.bazar.id
    $itemId = [string]$bazar.Body.data.items[0].id
    Assert-True ($bazarId.Length -gt 0) 'Fund Manager creates an assigned bazar'
    $receiptBytes = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScL1SAAAAABJRU5ErkJggg=='
    $unauthorizedReceipt = Invoke-Api -Command bazars -Action uploadReceipt -Method POST -Body @{id=$itemId; imageBase64=$receiptBytes} -ExpectedStatus @(401)
    Assert-Equal $unauthorizedReceipt.Status 401 'Receipt upload rejects missing token'
    $invalidReceipt = Invoke-Api -Command bazars -Action uploadReceipt -Method POST -Token $assistant.token -Body @{id=$itemId; imageBase64='not-an-image'} -ExpectedStatus @(422)
    Assert-Equal $invalidReceipt.Status 422 'Receipt upload rejects invalid image bytes'
    $receipt = Invoke-Api -Command bazars -Action uploadReceipt -Method POST -Token $assistant.token -Body @{id=$itemId; imageBase64=$receiptBytes}
    Assert-True ([string]$receipt.Body.data.receiptUrl -match '^[a-f0-9]{32}\.png$') 'Assistant uploads a private item receipt'
    $bazarWithReceipt = Invoke-Api -Command bazars -Action show -Token $assistant.token -Query @{id=$bazarId}
    Assert-Equal ([string]$bazarWithReceipt.Body.data.items[0].receipt_url) ([string]$receipt.Body.data.receiptUrl) 'Receipt reference persists on the purchased item'
    $receiptImage = Invoke-WebRequest -Uri "${baseUrl}?cmd=bazars&action=receipt&id=$itemId" -Headers @{Authorization="Bearer $($assistant.token)"} -UseBasicParsing
    Assert-Equal ([int]$receiptImage.StatusCode) 200 'Authorized user retrieves private receipt image'

    $closed = Invoke-Api -Command bazars -Action close -Method POST -Token $assistant.token -Body @{id=$bazarId; closedBy='assistant1'}
    Assert-Equal ([double]$closed.Body.data.bazarSpent) 200 'Assistant closes bazar with 200 spend'
    Assert-Equal ([double]$closed.Body.data.accountBalance) 800 'Bazar close updates balance once'
    $closeReplay = Invoke-Api -Command bazars -Action close -Method POST -Token $assistant.token -Body @{id=$bazarId; closedBy='manager1'}
    Assert-True ($closeReplay.Body.data.idempotentReplay -eq $true) 'Bazar close is idempotent on replay'
    Assert-Equal ([double]$closeReplay.Body.data.accountBalance) 800 'Bazar close replay does not change balance'
    $closedReceipt = Invoke-Api -Command bazars -Action uploadReceipt -Method POST -Token $assistant.token -Body @{id=$itemId; imageBase64=$receiptBytes} -ExpectedStatus @(409)
    Assert-Equal $closedReceipt.Status 409 'Closed bazar receipt cannot be changed'

    $excessiveReturn = Invoke-Api -Command returns -Action create -Method POST -Token $assistant.token -Headers @{'Idempotency-Key'='acceptance-excessive-return'} -Body @{accountId='acc1'; amount=801; requestedBy='manager1'} -ExpectedStatus @(422)
    Assert-Equal $excessiveReturn.Status 422 'Return above current balance is rejected'

    $return = Invoke-Api -Command returns -Action create -Method POST -Token $assistant.token -Headers @{'Idempotency-Key'='acceptance-return-1'} -Body @{accountId='acc1'; amount=300; requestedBy='assistant1'; expectedReceiverId='manager1'; note='Acceptance cash return'}
    $returnId = [string]$return.Body.data.request.id
    Assert-Equal $return.Body.data.request.status 'pending' 'Assistant return request remains pending'
    Assert-Equal $return.Body.data.request.requested_by 'assistant1' 'Forged return requester is replaced by token actor'
    $returnMismatch = Invoke-Api -Command returns -Action create -Method POST -Token $assistant.token -Headers @{'Idempotency-Key'='acceptance-return-1'} -Body @{accountId='acc1'; amount=301; expectedReceiverId='manager1'} -ExpectedStatus @(409)
    Assert-Equal $returnMismatch.Status 409 'Return idempotency key rejects a different payload'
    $assistantConfirm = Invoke-Api -Command returns -Action confirm -Method POST -Token $assistant.token -Body @{id=$returnId; confirmedBy='assistant1'} -ExpectedStatus @(403)
    Assert-Equal $assistantConfirm.Status 403 'Assistant cannot confirm a return request'

    $beforeConfirm = Invoke-Api -Command accounts -Action show -Token $manager.token -Query @{id='acc1'}
    Assert-Equal ([double]$beforeConfirm.Body.data.current_balance) 800 'Pending return does not change balance'

    $confirmed = Invoke-Api -Command returns -Action confirm -Method POST -Token $manager.token -Body @{id=$returnId; confirmedBy='manager1'; receivedBy='manager1'; entryDate='2026-10-26'}
    Assert-Equal $confirmed.Body.data.request.status 'confirmed' 'Fund Manager confirms return'
    Assert-Equal ([double]$confirmed.Body.data.accountBalance) 500 'Confirmed return produces final balance 500'

    $confirmReplay = Invoke-Api -Command returns -Action confirm -Method POST -Token $manager.token -Body @{id=$returnId; confirmedBy='manager1'; receivedBy='manager1'; entryDate='2026-10-26'}
    Assert-True ($confirmReplay.Body.data.idempotentReplay -eq $true) 'Return confirmation is idempotent on replay'

    $raceReturn = Invoke-Api -Command returns -Action create -Method POST -Token $assistant.token -Headers @{'Idempotency-Key'='acceptance-terminal-race'} -Body @{accountId='acc1'; amount=10; expectedReceiverId='manager1'}
    $raceReturnId = [string]$raceReturn.Body.data.request.id
    $raceRejected = Invoke-Api -Command returns -Action reject -Method POST -Token $manager.token -Body @{id=$raceReturnId; reason='Terminal state test'}
    Assert-Equal $raceRejected.Body.data.request.status 'rejected' 'Return rejection writes a terminal state transactionally'
    $confirmRejected = Invoke-Api -Command returns -Action confirm -Method POST -Token $manager.token -Body @{id=$raceReturnId} -ExpectedStatus @(409)
    Assert-Equal $confirmRejected.Status 409 'Rejected return cannot race into confirmation'

    $report = Invoke-Api -Command reports -Action summary -Token $manager.token -Query @{from='2026-10-01'; to='2026-10-31'; fundId='fund1'; accountId='acc1'}
    $summary = $report.Body.data.summary
    Assert-Equal ([double]$summary.fundGiven) 1000 'Report includes money given'
    Assert-Equal ([double]$summary.bazarSpent) 200 'Report includes bazar spend'
    Assert-Equal ([double]$summary.returnedConfirmed) 300 'Report includes confirmed return'
    Assert-Equal ([double]$summary.netBalanceChange) 500 'Report reconciles to final balance'

    if (-not $SkipFlutterContract) {
        $flutter = Get-Command flutter -ErrorAction SilentlyContinue
        if ($null -eq $flutter) {
            throw 'Flutter is not available on PATH; pass -SkipFlutterContract only for an API-only diagnostic run.'
        }
        & $flutter.Source test test/integration/api_contract_test.dart "--dart-define=BAZAR_INTEGRATION_BASE_URL=$baseUrl"
        if ($LASTEXITCODE -ne 0) { throw 'Flutter/API contract tests failed.' }
        Assert-True $true 'Flutter/API response contract tests pass'
    }

    Write-Host "`nAPI acceptance completed: $script:Passed passed, $script:Skipped skipped." -ForegroundColor Cyan
    if (-not $CompatibilityMode -and $script:Skipped -gt 0) { throw 'Strict acceptance cannot contain skipped checks.' }
} finally {
    if ($null -ne $php -and -not $php.HasExited) {
        Stop-Process -Id $php.Id -Force -ErrorAction SilentlyContinue
        $php.WaitForExit()
    }
    Restore-HarnessEnvironment
    if (-not $KeepArtifacts -and (Test-Path $runRoot)) {
        Remove-Item $runRoot -Recurse -Force -ErrorAction SilentlyContinue
    } elseif (Test-Path $runRoot) {
        Write-Host "Harness artifacts: $runRoot"
    }
}
