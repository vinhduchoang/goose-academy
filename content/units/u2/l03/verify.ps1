# Goose Contributor Academy - Lab check: u2-l03 Debug kit
<# Verifies notes about RUST_LOG defaults, span instrumentation in the
   scratch crate, snapshot knowledge, and thread observations. #>
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

$scratch = Join-Path (Get-Location) "u2-l03-scratch"
$notes = Join-Path (Get-Location) "u2-l03-notes.md"

# 1. Notes exist
Check "u2-l03-notes.md exists" (Test-Path $notes) "run all steps and record answers"

$notesRaw = if (Test-Path $notes) { Get-Content $notes -Raw } else { "" }

# 2. Notes explain why nothing printed without RUST_LOG
Check "notes explain default-filter silence" ($notesRaw -match "WARN|default|filter") "tie silence to goose=info + WARN defaults"

# 3. Notes record a root cause sentence for the overflow
Check "notes contain the root cause" ($notesRaw -match "root cause|overflow|80") "say which segment pushed the label past 80 chars"

# 4. Scratch main.rs has span instrumentation
$mainOk = $false
if (Test-Path (Join-Path $scratch "src\main.rs")) {
    $m = Get-Content (Join-Path $scratch "src\main.rs") -Raw
    $mainOk = ($m -match "#\[instrument") -and ($m -match "tracing")
}
Check "scratch src/main.rs uses #[instrument] + tracing" $mainOk "add #[instrument] to both functions"

# 5. Racy test file exists with atomic counter
$racyOk = $false
if (Test-Path (Join-Path $scratch "tests\racy.rs")) {
    $r = Get-Content (Join-Path $scratch "tests\racy.rs") -Raw
    $racyOk = ($r -match "AtomicUsize") -and ($r -match "#\[test\]")
}
Check "tests/racy.rs uses AtomicUsize in two tests" $racyOk "two tests sharing read-modify-write state"

# 6. Notes mention thread serialization observation
Check "notes cover --test-threads observation" ($notesRaw -match "test-threads|threads") "record which runs passed with 1 vs 8 threads"

# 7. Clone greps: filter defaults, snapshot assertion, CI serial run
$log = Join-Path $GooseRepo "crates\goose\src\logging.rs"
$filterOk = $false
if (Test-Path $log) { $filterOk = (Get-Content $log -Raw) -match "goose=info" }
Check "clone logging.rs has default goose=info directive" $filterOk "verify GOOSE_REPO path"

$pm = Join-Path $GooseRepo "crates\goose\src\agents\prompt_manager.rs"
$snapOk = $false
if (Test-Path $pm) { $snapOk = (Get-Content $pm -Raw) -match "assert_snapshot!" }
Check "clone prompt_manager.rs uses insta snapshots" $snapOk "expected assert_snapshot!(system_prompt)"

$ci = Join-Path $GooseRepo ".github\workflows\ci.yml"
$ciOk = $false
if (Test-Path $ci) { $ciOk = (Get-Content $ci -Raw) -match "scenario_tests::scenarios::tests" }
Check "clone ci.yml serializes scenario tests" $ciOk "expected --jobs 1 scenario_tests run"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}