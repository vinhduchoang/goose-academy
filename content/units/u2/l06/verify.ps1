# Goose Contributor Academy - Lab check: u2-l06 Agent-loop parity bug
<# Verifies the parity artifact: both universes located, both env pins in the
   test sketch, and the PR description. Plus clone greps for the switch. #>
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

$parity = Join-Path (Get-Location) "u2-l06-parity.md"
$notes = Join-Path (Get-Location) "u2-l06-notes.md"

# 1. Artifacts exist
Check "u2-l06-parity.md exists" (Test-Path $parity) "write patch sketches + test plan"
Check "u2-l06-notes.md exists" (Test-Path $notes) "record step 1 answers"

$p = if (Test-Path $parity) { Get-Content $parity -Raw } else { "" }
$n = if (Test-Path $notes) { Get-Content $notes -Raw } else { "" }

# 2. Both universes located
Check "parity file names the legacy site" (($p -match "agent\.rs|legacy") -and ($p -match "get\(" -or $p -match "get\(")) "legacy patch: get(..) + fallback sketch"
Check "parity file names the state-machine site" ($p -match "ops_toolcalling|state_machine") "patch sketch in the ops universe too"

# 3. Test sketch pins BOTH env values
Check "test sketch pins GOOSE_STATE_MACHINE=0" ($p -match 'GOOSE_STATE_MACHINE", Some\("0"\)|GOOSE_STATE_MACHINE = "0"') "legacy-mode pin required"
Check "test sketch pins GOOSE_STATE_MACHINE=1" ($p -match 'GOOSE_STATE_MACHINE", Some\("1"\)|GOOSE_STATE_MACHINE = "1"') "state-machine pin required"

# 4. Run matrix + PR parity section
Check "run matrix shows both env runs" (($p -match "GOOSE_STATE_MACHINE = .0.") -and ($p -match "GOOSE_STATE_MACHINE = .1.")) "two cargo test lines under both pins"
Check "PR section explains parity" ($p -match "Parity") "## Parity section with identical-behavior statement"

# 5. Notes record the switch answers
Check "notes list accepted enabled() values" ($p -match "'1'|true|TRUE|yes" -or $n -match "true|TRUE|yes") "four accepted spellings from mod.rs:74"

# 6. Clone greps: the switch, the legacy exit, the env pins
$sm = Join-Path $GooseRepo "crates\goose\src\agents\state_machine\mod.rs"
$smOk = $false
if (Test-Path $sm) {
    $s = Get-Content $sm -Raw
    $smOk = ($s -match "pub fn enabled") -and ($s -match "GOOSE_STATE_MACHINE")
}
Check "clone state_machine/mod.rs has enabled() switch" $smOk "verify GOOSE_REPO path"

$a = Join-Path $GooseRepo "crates\goose\src\agents\agent.rs"
$agOk = $false
if (Test-Path $a) { $agOk = (Get-Content $a -Raw) -match "state_machine::enabled" }
Check "clone agent.rs consults state_machine::enabled" $agOk "legacy/state-machine dispatch expected"

$ar = Join-Path $GooseRepo "crates\goose\src\agents\state_machine\tests\agent_reply.rs"
$arOk = $false
if (Test-Path $ar) { $arOk = (Get-Content $ar -Raw) -match "env_lock::lock_env" }
Check "clone agent_reply.rs pins env via env_lock" $arOk "env guard pattern expected"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}