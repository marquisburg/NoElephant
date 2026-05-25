# NoElephant smoke test: build db_demo, exercise CRUD, verify persistence.
param(
    [switch]$SkipBuild,
    [switch]$KeepTemp
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$DemoExe = Join-Path $RepoRoot "build\db_demo.exe"
$BuildBat = Join-Path $RepoRoot "build.bat"

function Write-Step([string]$Message) {
    Write-Host "==> $Message"
}

function Fail([string]$Message) {
    Write-Host "FAIL: $Message" -ForegroundColor Red
    exit 1
}

function Pass([string]$Message) {
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Invoke-DemoSession([string]$DbDir, [string]$Script) {
    $output = $Script | & $DemoExe $DbDir 2>&1
    $exitCode = $LASTEXITCODE
    return [pscustomobject]@{
        Output   = [string]::Join([Environment]::NewLine, @($output))
        ExitCode = $exitCode
    }
}

function Assert-NoErrors([string]$Label, [string]$Output) {
    if ($Output -match "(?m)^error:") {
        Fail "$Label reported SQL errors:`n$Output"
    }
}

function Assert-Match([string]$Label, [string]$Output, [string]$Pattern) {
    if ($Output -notmatch $Pattern) {
        Fail "$Label missing expected output '$Pattern'.`n$Output"
    }
}

Push-Location $RepoRoot
try {
    if (-not $SkipBuild) {
        Write-Step "Building db_demo"
        & $BuildBat | Out-Host
        if ($LASTEXITCODE -ne 0) {
            Fail "build.bat failed with exit code $LASTEXITCODE"
        }
    }

    if (-not (Test-Path $DemoExe)) {
        Fail "Missing $DemoExe. Run build.bat first."
    }

    $DbDir = Join-Path $env:TEMP ("noelephant-smoke-{0}" -f [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $DbDir | Out-Null
    Write-Step "Using temp database dir: $DbDir"

    $sessionSql = @"
CREATE TABLE users (id INT64, name TEXT)
INSERT INTO users VALUES (1, 'alice')
INSERT INTO users VALUES (2, 'bob')
SELECT * FROM users
UPDATE users SET name = 'alice2' WHERE id = 1
SELECT * FROM users WHERE id = 1
DELETE FROM users WHERE id = 2
SELECT * FROM users

"@

    Write-Step "Running CRUD session"
    $session = Invoke-DemoSession -DbDir $DbDir -Script $sessionSql
    if ($session.ExitCode -ne 0) {
        Fail "CRUD session exited with code $($session.ExitCode)`n$($session.Output)"
    }

    Assert-NoErrors "CRUD session" $session.Output
    Assert-Match "CRUD session" $session.Output "ok \(0 rows\)"
    Assert-Match "CRUD session" $session.Output "row 1: 1, alice"
    Assert-Match "CRUD session" $session.Output "row 2: 2, bob"
    Assert-Match "CRUD session" $session.Output "row 1: 1, alice2"
    Pass "CRUD session completed without errors"

    $reopenSql = @"
SELECT * FROM users

"@

    Write-Step "Reopening database and reading persisted rows"
    $reopen = Invoke-DemoSession -DbDir $DbDir -Script $reopenSql
    if ($reopen.ExitCode -ne 0) {
        Fail "Reopen session exited with code $($reopen.ExitCode)`n$($reopen.Output)"
    }

    Assert-NoErrors "Reopen session" $reopen.Output
    Assert-Match "Reopen session" $reopen.Output "row 1: 1, alice2"
    if ($reopen.Output -match "row 2:") {
        Fail "Reopen session still shows deleted row 2.`n$($reopen.Output)"
    }
    Pass "Persistence verified after reopen"

    Write-Host ""
    Write-Host "All smoke tests passed." -ForegroundColor Green
}
finally {
    Pop-Location
    if (-not $KeepTemp -and (Test-Path variable:DbDir) -and (Test-Path $DbDir)) {
        Remove-Item $DbDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    elseif ($KeepTemp -and (Test-Path variable:DbDir)) {
        Write-Host "Kept temp database dir: $DbDir"
    }
}
