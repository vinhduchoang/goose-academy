# Goose Contributor Academy - Lab check: u0-l04 Functions
# Run from the folder where you created lab04-fns.rs and lab04-notes.md.
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

# 1. The cited function exists in goose-provider-types
$basePath = Join-Path $GooseRepo "crates\goose-provider-types\src\base.rs"
$hasBase = Test-Path $basePath
if ($hasBase) {
    $b = Get-Content $basePath -Raw
    $fnOk = [bool]($b -match 'pub fn stream_from_single_message\(message: Message, usage: ProviderUsage\) -> MessageStream')
    Check "base.rs:457 stream_from_single_message present" $fnOk "signature missing"
} else {
    Check "goose-provider-types/src/base.rs exists" $false "repo may not be cloned: $GooseRepo"
}

# 2. count_tokens signature at token_counter.rs:53
$counterPath = Join-Path $GooseRepo "crates\goose\src\token_counter.rs"
if (Test-Path $counterPath) {
    $line53 = (Get-Content $counterPath)[52]
    $sigOk = [bool]($line53 -match 'pub fn count_tokens\(&self, text: &str\) -> usize')
    Check "token_counter.rs:53 count_tokens signature" $sigOk "saw: $line53"
} else {
    Check "token_counter.rs exists" $false "missing crates/goose/src/token_counter.rs"
}

# 3. Notes file created
$notesPath = Join-Path (Get-Location) "lab04-notes.md"
$hasNotes = Test-Path $notesPath
Check "lab04-notes.md created" $hasNotes "create lab04-notes.md (step 1 + step 3 + step 4 answers)"

# 4. Notes mention last-expression returns
if ($hasNotes) {
    $notes = Get-Content $notesPath -Raw
    $notesOk = [bool](($notes -match 'expression') -and ($notes -match 'return'))
    Check "notes discuss expression-returns vs early return" $notesOk "missing expression/return discussion"
}

# 5. Scratch file includes the ported helper
$srcPath = Join-Path (Get-Location) "lab04-fns.rs"
$hasSrc = Test-Path $srcPath
if ($hasSrc) {
    $src = Get-Content $srcPath -Raw
    $srcOk = [bool](($src -match 'fn char_truncate') -and ($src -match 'fn status_line') -and ($src -match 'FNS-OK'))
    Check "lab04-fns.rs has char_truncate, status_line, FNS-OK marker" $srcOk "missing required piece"
} else {
    Check "lab04-fns.rs created" $false "create lab04-fns.rs from lab step 2"
}

# 6. Compiles and all four tests PASS
if ($hasSrc) {
    $exe = Join-Path (Get-Location) "lab04-fns.exe"
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
        $passCount = ([regex]::Matches($run, '(?m)^PASS ')).Count
        $runOk = ([bool]($run -match 'FNS-OK') -and ($passCount -ge 4))
    }
    Check "compiles; at least 4 PASS lines and FNS-OK" $runOk "rustc said: $out"
}

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}