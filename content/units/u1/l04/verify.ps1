# Goose Contributor Academy - Lab check: u1-l04 Agent lifecycle I (legacy)
# Run from any directory. Validates the turn-trace notes + instrumentation snippets.
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

$agentPath = Join-Path $GooseRepo "crates\goose\src\agents\agent.rs"

# 1. The legacy entry chain functions exist at expected sites
$reply = Select-String -Path $agentPath -Pattern '^\s*pub async fn reply\(' -ErrorAction SilentlyContinue
$internal = Select-String -Path $agentPath -Pattern '^\s*async fn reply_internal\(' -ErrorAction SilentlyContinue
$context = Select-String -Path $agentPath -Pattern '^\s*async fn prepare_reply_context\(' -ErrorAction SilentlyContinue
Check "reply + reply_internal + prepare_reply_context exist in agents/agent.rs" ($null -ne $reply -and $null -ne $internal -and $null -ne $context) "expected the entry chain (drift?)"

# 2. dispatch_tool_call is the legacy dispatch site
$dtc = Select-String -Path $agentPath -Pattern '^\s*pub async fn dispatch_tool_call\(' -ErrorAction SilentlyContinue
Check "dispatch_tool_call defined in agent.rs" ($null -ne $dtc) "expected pub async fn dispatch_tool_call"

# 3. The legacy loop counter exists
$turns = Select-String -Path $agentPath -Pattern 'let mut turns_taken = 0u32' -ErrorAction SilentlyContinue
Check "legacy turn loop counter (turns_taken) present" ($null -ne $turns) "expected 'let mut turns_taken = 0u32'"

# 4. Chat-mode tool skip exists in the loop
$chat = Select-String -Path $agentPath -Pattern 'if goose_mode == GooseMode::Chat' -ErrorAction SilentlyContinue
Check "legacy loop has GooseMode::Chat tool-skip branch" ($null -ne $chat) "expected mode gate in reply loop"

# 5. Notes artifact: entry chain + turn table fully traced
$notesOk = $false
$notesPath = Join-Path (Get-Location) "l04-turn-log.md"
if (Test-Path $notesPath) {
    $notes = Get-Content $notesPath -Raw
    $notesOk = ($notes -match 'reply_internal') -and ($notes -match 'prepare_reply_context') -and
               ($notes -match 'dispatch_tool_call') -and ($notes -match 'turns_taken') -and
               ($notes -match 'tracing::info!')
}
Check "l04-turn-log.md traces entry chain, loop, dispatch + tracing snippet" $notesOk "complete Steps 1-3 first"

# 6. Legacy deltas answered (reply_parts sibling + method moved)
$deltaOk = $false
if (Test-Path $notesPath) {
    $notes = Get-Content $notesPath -Raw
    $deltaOk = ($notes -match 'reply_parts') -and ($notes -match 'reply_internal')
}
Check "l04-turn-log.md notes reply_parts legacy delta" $deltaOk "complete Step 5"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}