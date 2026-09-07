# Goose Contributor Academy - Lab check: u1-l05 State machine ops + effects
# Run from any directory. Validates the ops->legacy mapping work.
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

$stmDir = Join-Path $GooseRepo "crates\goose\src\agents\state_machine"

# 1. The executor crate owns the machine (evolved layout)
$machine = Select-String -Path (Join-Path $GooseRepo "crates\goose-agent\src\machine.rs") -Pattern '^pub struct StateMachine' -ErrorAction SilentlyContinue
Check "StateMachine defined in goose-agent/src/machine.rs" ($null -ne $machine) "expected 'pub struct StateMachine'"

# 2. goose re-exports the machine types
$reexp = Select-String -Path (Join-Path $stmDir "mod.rs") -Pattern 'pub use goose_agent::machine' -ErrorAction SilentlyContinue
Check "state_machine/mod.rs re-exports goose_agent::machine" ($null -ne $reexp) "expected re-export block"

# 3. ops files exist (spot-check the plan-named trio)
$llm = Test-Path (Join-Path $stmDir "ops_llm.rs")
$tc = Test-Path (Join-Path $stmDir "ops_toolcalling.rs")
$fx = Test-Path (Join-Path $stmDir "effects.rs")
Check "ops_llm.rs + ops_toolcalling.rs + effects.rs exist" ($llm -and $tc -and $fx) "missing ops files (drift?)"

# 4. GooseEffect is goose's effect extension
$gfx = Select-String -Path (Join-Path $stmDir "effects.rs") -Pattern '^pub enum GooseEffect' -ErrorAction SilentlyContinue
Check "GooseEffect enum exists in effects.rs" ($null -ne $gfx) "expected 'pub enum GooseEffect'"

# 5. create_state_machine assembles the ordered steps
$csm = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\agents\agent.rs") -Pattern 'fn create_state_machine' -ErrorAction SilentlyContinue
Check "create_state_machine exists in agents/agent.rs" ($null -ne $csm) "expected pub(super) fn create_state_machine"

# 6. GOOSE_STATE_MACHINE env gate exists
$gate = Select-String -Path (Join-Path $stmDir "mod.rs") -Pattern 'GOOSE_STATE_MACHINE' -ErrorAction SilentlyContinue
Check "GOOSE_STATE_MACHINE gate present in state_machine/mod.rs" ($null -ne $gate) "expected enabled() env check"

# 7. Notes artifact: mapping table + parity gap + effects paragraph
$notesOk = $false
$notesPath = Join-Path (Get-Location) "l05-ops-map.md"
if (Test-Path $notesPath) {
    $notes = Get-Content $notesPath -Raw
    $notesOk = ($notes -match 'ops_toolcalling') -and ($notes -match 'ops_compaction') -and
               ($notes -match 'dispatch_tool_call') -and ($notes -match 'GooseEffect') -and
               ($notes -match 'GOOSE_STATE_MACHINE')
}
Check "l05-ops-map.md covers ops mapping, legacy counterpart, GooseEffect, gate" $notesOk "complete Steps 1-5 first"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}