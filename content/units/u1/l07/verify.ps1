# Goose Contributor Academy - Lab check: u1-l07 Tool pipeline & permissions
# Run from any directory. Validates the permission pipeline trace work.
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

# 1. GooseMode postures exist
$mode = Select-String -Path (Join-Path $GooseRepo "crates\goose-provider-types\src\goose_mode.rs") -Pattern '^pub enum GooseMode' -ErrorAction SilentlyContinue
Check "GooseMode enum exists in goose-provider-types/src/goose_mode.rs" ($null -ne $mode) "expected pub enum GooseMode"

# 2. The three bucket types exist in the judge
$judge = Get-Content (Join-Path $GooseRepo "crates\goose\src\permission\permission_judge.rs") -Raw -ErrorAction SilentlyContinue
$buckets = ($judge -match 'approved') -and ($judge -match 'needs_approval') -and ($judge -match 'denied')
Check "PermissionCheckResult carries approved/needs_approval/denied" $buckets "expected the three buckets"

# 3. Security inspector implements ToolInspector
$sec = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\security\security_inspector.rs") -Pattern '^impl ToolInspector for SecurityInspector' -ErrorAction SilentlyContinue
Check "SecurityInspector implements ToolInspector" ($null -ne $sec) "expected impl ToolInspector for SecurityInspector"

# 4. Chat-mode gate exists in the legacy loop
$gate = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\agents\agent.rs") -Pattern 'if goose_mode == GooseMode::Chat' -ErrorAction SilentlyContinue
Check "legacy loop carries the GooseMode::Chat gate" ($null -ne $gate) "expected mode gate before inspection"

# 5. Decline/skip responses exist
$decl = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\agents\tool_execution.rs") -Pattern 'pub const DECLINED_RESPONSE' -ErrorAction SilentlyContinue
$skip = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\agents\tool_execution.rs") -Pattern 'CHAT_MODE_TOOL_SKIPPED_RESPONSE' -ErrorAction SilentlyContinue
Check "DECLINED_RESPONSE + CHAT_MODE_TOOL_SKIPPED_RESPONSE exist in tool_execution.rs" ($null -ne $decl -and $null -ne $skip) "expected the two response constants"

# 6. Notes artifact: module roles + bucket table + rejection trace
$notesOk = $false
$notesPath = Join-Path (Get-Location) "l07-tool-trace.md"
if (Test-Path $notesPath) {
    $notes = Get-Content $notesPath -Raw
    $notesOk = ($notes -match 'GooseMode') -and ($notes -match 'needs_approval') -and
               ($notes -match 'SecurityInspector') -and ($notes -match 'DECLINED_RESPONSE') -and
               ($notes -match 'patterns\.rs')
}
Check "l07-tool-trace.md covers modes, buckets, security patterns, decline text" $notesOk "complete Steps 1-5 first"

# 7. State-machine parity note present
$parOk = $false
if (Test-Path $notesPath) {
    $notes = Get-Content $notesPath -Raw
    $parOk = ($notes -match 'ToolApprovalOperation')
}
Check "l07-tool-trace.md maps the state-machine ToolApprovalOperation path" $parOk "complete Step 4.3"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}