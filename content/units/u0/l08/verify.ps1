# Goose Contributor Academy - Lab check: u0-l08 Borrowing
# Run from the folder where you created lab08-borrow.rs and lab08-notes.md.
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

# 1. count_tokens borrows &str
$counterPath = Join-Path $GooseRepo "crates\goose\src\token_counter.rs"
if (Test-Path $counterPath) {
    $c = Get-Content $counterPath -Raw
    $cOk = [bool]($c -match 'pub fn count_tokens\(&self, text: &str\) -> usize')
    Check "token_counter.rs:53 count_tokens(&self, &str)" $cOk "signature missing/changed"
} else {
    Check "token_counter.rs exists" $false "missing crates/goose/src/token_counter.rs"
}

# 2. hash_input borrows the message slice
$tpPath = Join-Path $GooseRepo "crates\goose\src\providers\testprovider.rs"
if (Test-Path $tpPath) {
    $tp = Get-Content $tpPath -Raw
    $tpOk = [bool](($tp -match 'fn hash_input\(messages: &\[Message\]\)') -and ($tp -match 'for content in &mut cleaned_content'))
    Check "testprovider.rs borrows &[Message] and &mut cleaned_content" $tpOk "borrow signatures missing"
} else {
    Check "testprovider.rs exists" $false "missing crates/goose/src/providers/testprovider.rs"
}

# 3. Notes with the three drill error codes
$notesPath = Join-Path (Get-Location) "lab08-notes.md"
$hasNotes = Test-Path $notesPath
Check "lab08-notes.md created" $hasNotes "create lab08-notes.md (steps 1, 3, 4 + homework)"
if ($hasNotes) {
    $notes = Get-Content $notesPath -Raw
    $a = ($notes -match 'E0502')
    $b = ($notes -match 'E0515')
    $c = ($notes -match 'E0506')
    Check "notes record borrow-drill errors (E0502/E0506/E0515)" ($a -or $b -or $c) "expected at least one borrow-error code in notes"
}

# 4. Scratch has trim_prompt(&str) -> &str and friends
$srcPath = Join-Path (Get-Location) "lab08-borrow.rs"
$hasSrc = Test-Path $srcPath
if ($hasSrc) {
    $src = Get-Content $srcPath -Raw
    $srcOk = [bool](($src -match 'fn trim_prompt\(prompt: &str\) -> &str') -and ($src -match 'fn first_word\(prompt: &str\) -> &str') -and ($src -match 'fn append_marker\(s: &mut String\)') -and ($src -match 'BORROW-OK'))
    Check "lab08-borrow.rs has trim_prompt, first_word, append_marker + marker" $srcOk "one or more required functions missing"
} else {
    Check "lab08-borrow.rs created" $false "create lab08-borrow.rs from lab step 2"
}

# 5. Compiles and prints BORROW-OK
if ($hasSrc) {
    $exe = Join-Path (Get-Location) "lab08-borrow.exe"
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
        $runOk = [bool](($run -match 'BORROW-OK') -and ($run -match 'trimmed'))
    }
    Check "lab08-borrow.rs compiles and prints BORROW-OK" $runOk "rustc said: $out"
}

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}