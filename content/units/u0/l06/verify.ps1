# Goose Contributor Academy - Lab check: u0-l06 Match & patterns
# Run from the folder where you created lab06-match.rs and lab06-notes.md.
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

# 1. RetryResult enum exists with a data-carrying variant
$retryPath = Join-Path $GooseRepo "crates\goose\src\agents\retry.rs"
if (Test-Path $retryPath) {
    $rr = Get-Content $retryPath -Raw
    $rrOk = [bool](($rr -match 'pub enum RetryResult') -and ($rr -match 'MaxAttemptsReached\(Message\)'))
    Check "retry.rs:23 RetryResult with Message payload" $rrOk "enum or payload variant missing"
} else {
    Check "agents/retry.rs exists" $false "missing crates/goose/src/agents/retry.rs"
}

# 2. SuccessCheck enum in agents/types.rs
$typesPath = Join-Path $GooseRepo "crates\goose\src\agents\types.rs"
if (Test-Path $typesPath) {
    $t = Get-Content $typesPath -Raw
    $scOk = [bool](($t -match 'pub enum SuccessCheck') -and ($t -match 'Shell \{'))
    Check "types.rs:61 SuccessCheck with Shell variant" $scOk "enum shape missing"
} else {
    Check "agents/types.rs exists" $false "missing crates/goose/src/agents/types.rs"
}

# 3. Notes file records the exhaustiveness experiment
$notesPath = Join-Path (Get-Location) "lab06-notes.md"
$hasNotes = Test-Path $notesPath
Check "lab06-notes.md created" $hasNotes "create lab06-notes.md (steps 1, 3, 4)"
if ($hasNotes) {
    $notes = Get-Content $notesPath -Raw
    $notesOk = [bool](($notes -match 'E0004') -and ($notes -match 'ref mut'))
    Check "notes mention E0004 and ref mut destructuring" $notesOk "missing E0004 or ref mut discussion"
}

# 4. Scratch uses match, if let, matches! and the marker
$srcPath = Join-Path (Get-Location) "lab06-match.rs"
$hasSrc = Test-Path $srcPath
if ($hasSrc) {
    $src = Get-Content $srcPath -Raw
    $srcOk = [bool](($src -match 'match cmd') -and ($src -match 'if let') -and ($src -match 'matches!') -and ($src -match 'MATCH-OK'))
    Check "lab06-match.rs has match/if let/matches! + marker" $srcOk "one or more constructs missing"
} else {
    Check "lab06-match.rs created" $false "create lab06-match.rs from lab step 2"
}

# 5. Compiles and prints MATCH-OK
if ($hasSrc) {
    $exe = Join-Path (Get-Location) "lab06-match.exe"
    Remove-Item $exe -ErrorAction SilentlyContinue
    $savedA = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $out = (& rustc --edition 2021 $srcPath -o $exe 2>&1 | Out-String)
    $ErrorActionPreference = $savedA
    $runOk = $false
    if (Test-Path $exe) {
        $savedB = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        $run = (& $exe 2>&1 | Out-String)
        $ErrorActionPreference = $savedB
        $runOk = [bool](($run -match 'MATCH-OK') -and ($run -match 'important toasts'))
    }
    Check "lab06-match.rs compiles and prints MATCH-OK" $runOk "rustc said: $out"
}

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}