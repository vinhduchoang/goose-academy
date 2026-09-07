# Goose Contributor Academy - Lab check: u0-l05 Control flow
# Run from the folder where you created lab05-turns.rs and lab05-notes.md.
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

# 1. The per-tool loop exists in the real code
$counterPath = Join-Path $GooseRepo "crates\goose\src\token_counter.rs"
if (Test-Path $counterPath) {
    $line78 = (Get-Content $counterPath)[77]
    $loopOk = [bool]($line78 -match 'for tool in tools')
    Check "token_counter.rs:78 loops for tool in tools" $loopOk "saw: $line78"
} else {
    Check "token_counter.rs exists" $false "missing crates/goose/src/token_counter.rs"
}

# 2. Iterator chain in usage_estimator.rs
$uePath = Join-Path $GooseRepo "crates\goose\src\providers\usage_estimator.rs"
if (Test-Path $uePath) {
    $ue = Get-Content $uePath -Raw
    $chainOk = [bool](($ue -match '\.map\(\|c\| format!') -and ($ue -match '\.collect::<Vec<_>>\(\)') -and ($ue -match '\.join\(" "\)'))
    Check "usage_estimator.rs maps content blocks and joins" $chainOk "iterator chain missing"
} else {
    Check "usage_estimator.rs exists" $false "missing crates/goose/src/providers/usage_estimator.rs"
}

# 3. Notes file created and discusses loops/chains
$notesPath = Join-Path (Get-Location) "lab05-notes.md"
$hasNotes = Test-Path $notesPath
Check "lab05-notes.md created" $hasNotes "create lab05-notes.md (steps 1, 3, 4)"
if ($hasNotes) {
    $notes = Get-Content $notesPath -Raw
    $notesOk = [bool](($notes -match 'accumulate') -and ($notes -match 'filter_map'))
    Check "notes cover the accumulator and filter_map" $notesOk "missing accumulator/filter_map discussion"
}

# 4. Scratch file has the required constructs
$srcPath = Join-Path (Get-Location) "lab05-turns.rs"
$hasSrc = Test-Path $srcPath
if ($hasSrc) {
    $src = Get-Content $srcPath -Raw
    $srcOk = [bool](($src -match 'for t in &turns') -and ($src -match 'while ') -and ($src -match 'loop \{') -and ($src -match 'continue') -and ($src -match 'CONTROL-OK'))
    Check "lab05-turns.rs uses for/while/loop/continue + marker" $srcOk "one or more constructs missing"
} else {
    Check "lab05-turns.rs created" $false "create lab05-turns.rs from lab step 2"
}

# 5. Broken file records the lesson (existence only - mistakes are expected)
$brokenPath = Join-Path (Get-Location) "lab05-broken.rs"
$hasBroken = Test-Path $brokenPath
Check "lab05-broken.rs created (on-purpose mistake)" $hasBroken "create the broken copy from lab step 3 (then delete or keep - notes just need the error text)"

# 6. Compiles and prints CONTROL-OK
if ($hasSrc) {
    $exe = Join-Path (Get-Location) "lab05-turns.exe"
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
        $runOk = [bool](($run -match 'CONTROL-OK') -and ($run -match 'shrunk window'))
    }
    Check "lab05-turns.rs compiles and prints CONTROL-OK" $runOk "rustc said: $out"
}

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}