# Goose Contributor Academy - Lab check: u1-l06 Providers deep dive
# Run from any directory. Validates provider trait/format/cost tracing work.
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

# 1. Provider trait is streaming-first with complete() as default
$trait = Select-String -Path (Join-Path $GooseRepo "crates\goose-provider-types\src\base.rs") -Pattern '^pub trait Provider: Send \+ Sync' -ErrorAction SilentlyContinue
$stream = Select-String -Path (Join-Path $GooseRepo "crates\goose-provider-types\src\base.rs") -Pattern '^\s*async fn stream\(' -ErrorAction SilentlyContinue
Check "Provider trait + stream() exist in goose-provider-types/src/base.rs" ($null -ne $trait -and $null -ne $stream) "expected trait with async fn stream"

# 2. OpenAiProvider implements Provider in goose-providers
$oai = Select-String -Path (Join-Path $GooseRepo "crates\goose-providers\src\openai.rs") -Pattern '^impl Provider for OpenAiProvider' -ErrorAction SilentlyContinue
Check "impl Provider for OpenAiProvider exists in goose-providers/src/openai.rs" ($null -ne $oai) "expected impl block"

# 3. Formats layer exists with format_messages
$fmt = Select-String -Path (Join-Path $GooseRepo "crates\goose-provider-types\src\formats\openai.rs") -Pattern '^pub fn format_messages' -ErrorAction SilentlyContinue
$fix = Select-String -Path (Join-Path $GooseRepo "crates\goose-provider-types\src\formats\openai.rs") -Pattern 'fn merge_split_tool_call_messages' -ErrorAction SilentlyContinue
Check "formats/openai.rs has format_messages + merge_split_tool_call_messages" ($null -ne $fmt -and $null -ne $fix) "expected envelope translation helpers"

# 4. Canonical cost estimator exists
$cost = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\providers\canonical_cost.rs") -Pattern 'pub fn estimate_model_cost' -ErrorAction SilentlyContinue
Check "estimate_model_cost defined in providers/canonical_cost.rs" ($null -ne $cost) "expected canonical pricing lookup"

# 5. Usage struct + token counter exist (the account units)
$usage = Select-String -Path (Join-Path $GooseRepo "crates\goose-provider-types\src\conversation\token_usage.rs") -Pattern '^pub struct Usage' -ErrorAction SilentlyContinue
$tok = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\token_counter.rs") -Pattern 'create_token_counter' -ErrorAction SilentlyContinue
Check "Usage struct + create_token_counter exist" ($null -ne $usage -and $null -ne $tok) "expected token accounting units"

# 6. Notes artifact: trait summary + stream reading + streaming-breaks analysis
$notesOk = $false
$notesPath = Join-Path (Get-Location) "l06-provider-notes.md"
if (Test-Path $notesPath) {
    $notes = Get-Content $notesPath -Raw
    $notesOk = ($notes -match 'complete') -and ($notes -match 'stream_for_model') -and
               ($notes -match 'merge_split_tool_call_messages') -and ($notes -match 'estimate_model_cost')
}
Check "l06-provider-notes.md covers trait defaults, OpenAI stream, formats fix, cost" $notesOk "complete Steps 1-5 first"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}