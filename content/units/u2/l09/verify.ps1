# Goose Contributor Academy - Lab check: u2-l09 Performance & memory
<# Verifies the profile notes with before/after numbers, the scratch bench
   (cache + spill), and greps in the clone for the three economic files. #>
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

$scratch = Join-Path (Get-Location) "u2-l09-scratch"
$notes = Join-Path (Get-Location) "u2-l09-notes.md"
$profile = Join-Path (Get-Location) "u2-l09-profile.md"

# 1. Profile artifact with measurable before/after numbers
$profOk = $false
if (Test-Path $profile) {
    $p = Get-Content $profile -Raw
    $profOk = ($p -match "Before") -and ($p -match "After") -and ($p -match "\d+(\.\d+)?\s*(ms|s)|µs")
}
Check "u2-l09-profile.md has before/after numbers" $profOk "average at least 3 release runs, include units"

$profRaw = if (Test-Path $profile) { Get-Content $profile -Raw } else { "" }
Check "profile states the improvement factor" ($profRaw -match "Improvement") "one measurable line: x faster / slower"

# 2. Scratch bench implements the cached pattern
$mainRaw = ""
$mainOk = Test-Path (Join-Path $scratch "src\main.rs")
if ($mainOk) { $mainRaw = Get-Content (Join-Path $scratch "src\main.rs") -Raw }
Check "bench uses Instant timing" ($mainOk -and ($mainRaw -match "Instant")) "std::time::Instant around both callers"
Check "bench has naive + cached callers" ($mainOk -and ($mainRaw -match "naive") -and ($mainRaw -match "cached|HashMap")) "memoized path keyed by string"

# 3. Spill-if-huge structural improvement present
Check "bench has spill_if_huge with pointer/branches" ($mainOk -and ($mainRaw -match "spill_if_huge|threshold|pointer")) "temp file + pointer string contract"

# 4. Notes cover the three real economic files + config keys
$notesRaw = if (Test-Path $notes) { Get-Content $notes -Raw } else { "" }
Check "notes exist" (Test-Path $notes) "u2-l09-notes.md required"
Check "notes mention token_counter cache key" ($notesRaw -match "blake3|hash") "explain (len, hash) identity key"
Check "notes mention spill threshold override" ($notesRaw -match "GOOSE_MAX_TOOL_RESPONSE_SIZE") "env override name"
Check "notes mention context limit validation" ($notesRaw -match "GOOSE_CONTEXT_LIMIT") "greater than 0 rule"

# 5. Clone greps for the three files
$tc = Join-Path $GooseRepo "crates\goose\src\token_counter.rs"
$tcOk = $false
if (Test-Path $tc) { $tcOk = (Get-Content $tc -Raw) -match "MAX_TOKEN_CACHE_SIZE" }
Check "clone token_counter.rs has bounded cache const" $tcOk "verify GOOSE_REPO path"

$lrh = Join-Path $GooseRepo "crates\goose\src\agents\large_response_handler.rs"
$lrhOk = $false
if (Test-Path $lrh) { $lrhOk = (Get-Content $lrh -Raw) -match "200_000" }
Check "clone large_response_handler has the 200k threshold" $lrhOk "expected DEFAULT_LARGE_TEXT_THRESHOLD"

$cl = Join-Path $GooseRepo "crates\goose\src\context_limit.rs"
Check "clone context_limit.rs exists" (Test-Path $cl) "provider-backed limit expected"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}