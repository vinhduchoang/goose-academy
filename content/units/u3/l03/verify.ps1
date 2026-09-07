<# Goose Contributor Academy - Lab check: u3-l03 Provider streaming/usage/cost/telemetry
   Checks the upgraded echo crate: multi-chunk stream, ProviderStats timing,
   chat-shaped token estimation, cost function, telemetry-span test, notes,
   and goose-repo grep evidence for the fallback + pricing code.
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

# The echo crate may live directly in LabDir or in LabDir\echo-ext
$crateDir = $LabDir
if (-not (Test-Path (Join-Path $crateDir "Cargo.toml"))) {
    $crateDir = Join-Path $LabDir "echo-ext"
}

$libPath = Join-Path $crateDir "src\lib.rs"
$lib = if (Test-Path $libPath) { Get-Content $libPath -Raw } else { "" }

# 1. True multi-chunk streaming (futures::stream / async_stream in stream())
Check "stream emits multiple chunks via futures::stream" `
    ($lib -match 'stream::iter' -or $lib -match 'async_stream' -or $lib -match 'stream::once|stream::unfold') `
    "build a word-by-word chunk iterator in Step 1"

# 2. Final usage-only chunk pattern (Option tuple shape)
Check "usage lands on the final chunk (Option tuple items)" `
    ($lib -match '\(Some\(' ) `
    "chunks are (Option<Message>, Option<ProviderUsage>) items"

# 3. ProviderStats timing fields filled
Check "ProviderStats records time_to_first_token_ms + elapsed_ms" `
    ($lib -match 'time_to_first_token_ms' -and $lib -match 'elapsed_ms') `
    "populate ProviderStats with Instant timings from Step 3"

# 4. Chat-shaped token estimation helper + overhead accounting
Check "estimate_chat_tokens helper exists (chat-shaped, not whitespace-only)" `
    ($lib -match 'estimate_chat_tokens') `
    "add fn estimate_chat_tokens per Step 2"

# 5. Cost function from per-1M-token pricing
Check "estimate_cost computes USD from per-1M-token rates" `
    ($lib -match 'estimate_cost' -and $lib -match '1_000_000') `
    "implement LinearPricing + estimate_cost per Step 3"

# 6. Telemetry pattern test replicating gen_ai.usage attributes
$a = Select-String -Path (Join-Path $crateDir "src\lib.rs"), (Join-Path $crateDir "tests\*") -Pattern 'gen_ai\.usage\.' -ErrorAction SilentlyContinue
Check "test records gen_ai.usage.* attributes (telemetry pattern)" ($null -ne $a) "add the span-attribute test from Step 4"

# 7. Notes capture the fallback + pricing precedence
$notesPath = Join-Path $LabDir "u3-l03-notes.md"
$notes = if (Test-Path $notesPath) { Get-Content $notesPath -Raw } else { "" }
Check "u3-l03-notes.md records ensure_usage_tokens order + 4-tier pricing precedence" `
    ($notes -match 'ensure_usage_tokens' -and $notes -match 'precedence') `
    "create u3-l03-notes.md from Steps 2-3"

# 8. Goose-repo evidence: fallback + pricing live in the repo
$m = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\providers\canonical_cost.rs") -Pattern 'estimate_model_cost' -ErrorAction SilentlyContinue
Check "goose repo: estimate_model_cost found in canonical_cost.rs" ($null -ne $m) "grep crates/goose/src/providers/canonical_cost.rs"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}