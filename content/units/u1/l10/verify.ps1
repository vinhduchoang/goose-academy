# Goose Contributor Academy - Lab check: u1-l10 Session & context
# Run from any directory. Validates the compaction / context limit trace work.
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

# 1. SessionManager + Session live in session/session_manager.rs
$sm = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\session\session_manager.rs") -Pattern '^pub struct SessionManager' -ErrorAction SilentlyContinue
$s = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\session\session_manager.rs") -Pattern '^pub struct Session \{' -ErrorAction SilentlyContinue
Check "SessionManager + Session defined in session/session_manager.rs" ($null -ne $sm -and $null -ne $s) "expected both structs"

# 2. Compaction brain extracted into its own crate
$brain = Test-Path (Join-Path $GooseRepo "crates\goose-context-management\src\summarize.rs")
Check "goose-context-management crate holds compaction (summarize.rs)" $brain "expected extracted crate"

# 3. Compaction wiring exists in goose
$cc = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\context_mgmt\mod.rs") -Pattern 'pub async fn compact_messages' -ErrorAction SilentlyContinue
$cn = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\context_mgmt\mod.rs") -Pattern 'check_if_compaction_needed' -ErrorAction SilentlyContinue
Check "compact_messages + check_if_compaction_needed exist in context_mgmt/mod.rs" ($null -ne $cc -and $null -ne $cn) "expected compaction driver + trigger"

# 4. The double-compaction cap exists in the state machine op
$cap = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\agents\state_machine\ops_compaction.rs") -Pattern 'MAX_CONTEXT_ERROR_COMPACTIONS' -ErrorAction SilentlyContinue
Check "MAX_CONTEXT_ERROR_COMPACTIONS cap exists in ops_compaction.rs" ($null -ne $cap) "expected the =2 cap"

# 5. History search module exists
$hs = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\session\chat_history_search.rs") -Pattern '^pub struct ChatHistorySearch' -ErrorAction SilentlyContinue
Check "ChatHistorySearch defined in session/chat_history_search.rs" ($null -ne $hs) "expected pub struct ChatHistorySearch"

# 6. Notes artifact covers threshold chain + splice + honest search answer
$notesOk = $false
$notesPath = Join-Path (Get-Location) "l10-context-notes.md"
if (Test-Path $notesPath) {
    $notes = Get-Content $notesPath -Raw
    $notesOk = ($notes -match 'GOOSE_AUTO_COMPACT_THRESHOLD') -and ($notes -match 'compact_messages') -and
               ($notes -match 'MAX_CONTEXT_ERROR_COMPACTIONS') -and ($notes -match 'ChatHistorySearch|chat_history_search')
}
Check "l10-context-notes.md traces threshold, splice, cap, history search" $notesOk "complete Steps 1-5 first"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}