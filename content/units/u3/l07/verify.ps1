<# Goose Contributor Academy - Lab check: u3-l07 MCP hardening
   Checks the hardened notes-server: bounded input, informative ErrorData,
   timeout branch, elicitation mapping, auth boundary, failure-branch
   tests, notes, and goose-repo grep evidence.
#>
param(
    [string]$GooseRepo = $env:GOOSE_REPO,
    [string]$LabDir = (Get-Location).Path
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

# The server crate may live directly in LabDir or in LabDir\notes-server
$crateDir = $LabDir
if (-not (Test-Path (Join-Path $crateDir "Cargo.toml"))) {
    $crateDir = Join-Path $LabDir "notes-server"
}

$mainPath = Join-Path $crateDir "src\main.rs"
$main = if (Test-Path $mainPath) { Get-Content $mainPath -Raw } else { "" }

# 1. Bounded input: max length + tag allowlist
Check "input bounds enforced (MAX_NOTE_LEN + tag pattern)" `
    ($main -match 'MAX_NOTE_LEN' -and $main -match '\^\[a-z0-9-\]') `
    "add the length cap and tag allowlist from Step 2"

# 2. Informative INVALID_PARAMS errors
Check "failures return informative ErrorData (INVALID_PARAMS)" `
    ($main -match 'INVALID_PARAMS' -and $main -match 'ErrorData::new') `
    "reject caller faults with INVALID_PARAMS and a helpful message"

# 3. Timeout branch with tokio::time::timeout
Check "tokio::time::timeout guards slow work with a distinct message" `
    ($main -match 'tokio::time::timeout|timeout\(' -and $main -match 'timed out') `
    "wrap the slow scan per Step 3"

# 4. Elicitation: request_elicitation + Accept/Decline/Cancel handling
Check "elicitation tool maps Accept/Decline/Cancel" `
    ($main -match 'request_elicitation' -and $main -match 'ElicitationAction') `
    "add confirm_overwrite per Step 4"

# 5. Auth boundary: authorization meta header + INVALID_REQUEST
Check "auth check reads meta header and rejects with INVALID_REQUEST" `
    ($main -match 'authorization' -and $main -match 'INVALID_REQUEST') `
    "add check_auth per Step 5"

# 6. Pure validation extracted for tests
Check "validate_note extracted as pure fn for cheap tests" `
    ($main -match 'validate_note') `
    "extract validation per Step 6"

# 7. Failure-branch tests present
$testText = ""
$testsDir = Join-Path $crateDir "tests"
$testFiles = @()
if (Test-Path $testsDir) { $testFiles = Get-ChildItem $testsDir -Filter *.rs -ErrorAction SilentlyContinue }
foreach ($t in $testFiles) { $testText += (Get-Content $t.FullName -Raw) }
$inline = $main -match '#\[test\]' -or $main -match '#\[tokio::test\]'
Check "tests cover failure branches (inline or tests/)" `
    ($inline -or ($testText -match 'validate_note|too long|INVALID')) `
    "add the tests from Step 6"

# 8. Notes record outcome alphabet + auth doors
$notesPath = Join-Path $LabDir "u3-l07-notes.md"
$notes = if (Test-Path $notesPath) { Get-Content $notesPath -Raw } else { "" }
Check "u3-l07-notes.md records ElicitationOutcome + both auth doors" `
    ($notes -match 'ElicitationOutcome' -and $notes -match 'streamable_http') `
    "create u3-l07-notes.md per Steps 1 and 5"

# 9. Goose-repo evidence: elicitation + AuthRequired path
$hits = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\action_required_manager.rs") -Pattern 'ElicitationOutcome' -ErrorAction SilentlyContinue
$hits2 = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\agents\extension_manager.rs") -Pattern 'create_streamable_http_client' -ErrorAction SilentlyContinue
Check "goose repo: ElicitationOutcome + create_streamable_http_client found" (($null -ne $hits) -and ($null -ne $hits2)) "grep action_required_manager.rs + extension_manager.rs"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}