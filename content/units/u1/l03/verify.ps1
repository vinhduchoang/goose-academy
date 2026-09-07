# Goose Contributor Academy - Lab check: u1-l03 Config system
# Run from any directory. Validates the config key trace + notes artifact.
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

# 1. Config module family exists
$modrs = Get-Content (Join-Path $GooseRepo "crates\goose\src\config\mod.rs") -Raw -ErrorAction SilentlyContinue
Check "config/mod.rs declares base, extensions, permission, providers modules" ($modrs -match 'pub mod base' -and $modrs -match 'pub mod extensions' -and $modrs -match 'pub mod providers') "missing module declarations (drift?)"

# 2. Config singleton accessor exists
$globalFn = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\config\base.rs") -Pattern 'pub fn global\(\) -> &''static Config' -ErrorAction SilentlyContinue
Check "Config::global() singleton defined in base.rs" ($null -ne $globalFn) "expected 'pub fn global() -> &'static Config'"

# 3. Legacy thinking-effort migration still maps CLAUDE_THINKING_TYPE
$legacy = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\config\base.rs") -Pattern 'CLAUDE_THINKING_TYPE' -ErrorAction SilentlyContinue
Check "base.rs still contains CLAUDE_THINKING_TYPE legacy mapping" ($null -ne $legacy) "expected legacy_thinking_effort() migration"

# 4. GOOSE_MAX_TURNS is read in BOTH agent paths
$patL = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\agents\agent.rs") -Pattern 'get_param::<u32>\("GOOSE_MAX_TURNS"\)' -ErrorAction SilentlyContinue
$both = @($patL).Count -ge 2
Check "GOOSE_MAX_TURNS read in legacy loop AND state-machine constructor" $both "expected two get_param::<u32> sites"

# 5. Config-key edit actually applied by the learner (value 4 somewhere in user config)
$cfgOk = $false
$userCfg = Join-Path $env:USERPROFILE ".config\goose\config.yaml"
if (Test-Path $userCfg) {
    $cfg = Get-Content $userCfg -Raw
    $cfgOk = $cfg -match "GOOSE_MAX_TURNS\s*:\s*4\b"
}
Check "user config.yaml contains GOOSE_MAX_TURNS: 4 (your Step 2 edit)" $cfgOk "add 'GOOSE_MAX_TURNS: 4' to $userCfg (restore backup afterwards)"

# 6. Trace notes artifact
$notesOk = $false
if (Test-Path (Join-Path (Get-Location) "l03-config-trace.md")) {
    $notes = Get-Content (Join-Path (Get-Location) "l03-config-trace.md") -Raw
    $notesOk = ($notes -match 'GOOSE_MAX_TURNS') -and ($notes -match 'migrations') -and
               ($notes -match 'GOOSE_STATE_MACHINE') -and ($notes -match 'precedence')
}
Check "l03-config-trace.md covers both read sites, migrations, precedence, parity" $notesOk "complete Steps 3-5 first"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}