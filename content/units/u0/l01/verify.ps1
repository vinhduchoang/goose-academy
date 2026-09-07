# Goose Contributor Academy - Lab check: u0-l01 Toolchain
# Run from any directory. Validates your goose checkout is buildable
# and you understand the workspace layout.
param(
    [string]$GooseRepo = $env:GOOSE_REPO
)

$ErrorActionPreference = "Stop"
$fails = 0
$passes = 0

if (-not $GooseRepo) {
    $GooseRepo = "C:\Users\admin\projects\goose"
    Write-Host "[INFO]  GOOSE_REPO not set; trying default: $GooseRepo"
}

function Check {
    param([string]$Name, [bool]$Ok, [string]$Detail)
    if ($Ok) {
        Write-Host "[PASS]  $Name"
        $script:passes++
    } else {
        Write-Host "[FAIL]  $Name - $Detail"
        $script:fails++
    }
}

# 1. The repo exists and has the workspace manifest
$hasCargoToml = Test-Path (Join-Path $GooseRepo "Cargo.toml")
Check "goose repo contains Cargo.toml" $hasCargoToml "cloned repo? path=$GooseRepo"

# 2. The Justfile (precommit gate) exists
$hasJustfile = Test-Path (Join-Path $GooseRepo "Justfile")
Check "Justfile exists at repo root" $hasJustfile "missing Justfile"

# 3. Workspace members resolve via cargo metadata
$membersOk = $false
if ($hasCargoToml) {
    Push-Location $GooseRepo
    try {
        $json = cargo metadata --no-deps --format-version 1 | ConvertFrom-Json
        $names = @($json.packages | ForEach-Object { $_.name })
        $membersOk = ($names -contains "goose") -and ($names -contains "goose-cli")
        $memberCount = $names.Count
    } catch {
        $membersOk = $false
    } finally {
        Pop-Location
    }
    Check "cargo metadata lists goose + goose-cli" $membersOk ("saw $memberCount packages")
}

# 4. resolver = "2" is present in the workspace manifest
$rootToml = Get-Content (Join-Path $GooseRepo "Cargo.toml") -Raw
$resolverOk = $rootToml -match 'resolver\s*=\s*"2"'
Check 'workspace uses resolver = "2"' $resolverOk "expected resolver=2 in root Cargo.toml"

# 5. Your notes from step 3 exist
$notesOk = Test-Path (Join-Path (Get-Location) "lab01-notes.md")
Check "lab01-notes.md created" $notesOk "create lab01-notes.md (crate map + 2 answers) first"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}