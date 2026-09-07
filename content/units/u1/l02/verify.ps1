# Goose Contributor Academy - Lab check: u1-l02 Core data model
# Run from any directory. Validates Message/MessageContentBlock tracing work.
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

# 1. The datamodel lives in goose-provider-types
$msg = Select-String -Path (Join-Path $GooseRepo "crates\goose-provider-types\src\conversation\message.rs") -Pattern '^pub struct Message \{' -ErrorAction SilentlyContinue
Check "Message struct defined in goose-provider-types/src/conversation/message.rs" ($null -ne $msg) "expected 'pub struct Message {'"

# 2. MessageContentBlock enum exists with ToolRequest variant
$mc = Get-Content (Join-Path $GooseRepo "crates\goose-provider-types\src\conversation\message.rs") -Raw -ErrorAction SilentlyContinue
Check "MessageContentBlock declares Text and ToolRequest variants" ($mc -match 'pub enum MessageContentBlock' -and $mc -match 'ToolRequest\(ToolRequest\)') "re-read lines 318-330"

# 3. Legacy ReplyPart is gone (drift check)
$legacy = $false
if (Test-Path (Join-Path $GooseRepo "crates")) {
    $rp = Get-ChildItem (Join-Path $GooseRepo "crates") -Recurse -Filter *.rs -ErrorAction SilentlyContinue |
        Select-String -Pattern "ReplyPart" -ErrorAction SilentlyContinue
    $legacy = ($null -ne $rp)
}
Check "no ReplyPart symbol remains anywhere under crates/ (evolved model)" (-not $legacy) "use Select-String; expect zero matches"

# 4. ModelConfig exists in the type crate
$mcfg = Select-String -Path (Join-Path $GooseRepo "crates\goose-provider-types\src\model.rs") -Pattern '^pub struct ModelConfig \{' -ErrorAction SilentlyContinue
Check "ModelConfig struct defined in goose-provider-types/src/model.rs" ($null -ne $mcfg) "expected 'pub struct ModelConfig {'"

# 5. Notes artifact contains the flow + evidence
$notesOk = $false
if (Test-Path (Join-Path (Get-Location) "l02-flow.md")) {
    $notes = Get-Content (Join-Path (Get-Location) "l02-flow.md") -Raw
    $notesOk = ($notes -match 'MessageContentBlock') -and ($notes -match 'ModelConfig') -and
               ($notes -match 'deserialize_sanitized_content') -and ($notes -match 'mermaid')
}
Check "l02-flow.md covers variants, ModelConfig, deserializer + mermaid diagram" $notesOk "complete Steps 1-5 first"

# 6. Learner located the tool-execution hop
$hopOk = $false
if (Test-Path (Join-Path (Get-Location) "l02-flow.md")) {
    $notes = Get-Content (Join-Path (Get-Location) "l02-flow.md") -Raw
    $hopOk = ($notes -match 'tool_execution\.rs') -and ($notes -match 'categorize_tool_requests')
}
Check "l02-flow.md cites tool_execution.rs and categorize_tool_requests" $hopOk "complete Step 3 with file:line hops"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}