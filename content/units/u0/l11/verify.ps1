# Goose Contributor Academy - Lab check: u0-l11 Enums, Option, Result
# Run from the folder where you created lab11-result.rs and lab11-notes.md.
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

# 1. ProviderError enum with data-carrying variants
$errPath = Join-Path $GooseRepo "crates\goose-provider-types\src\errors.rs"
if (Test-Path $errPath) {
    $e = Get-Content $errPath -Raw
    $eOk = [bool](($e -match 'pub enum ProviderError') -and ($e -match 'NotConfigured,') -and ($e -match 'NotImplemented\(String\)'))
    Check "errors.rs:7 ProviderError with NotConfigured + NotImplemented(String)" $eOk "variants missing"
} else {
    Check "goose-provider-types/src/errors.rs exists" $false "missing crates/goose-provider-types/src/errors.rs"
}

# 2. Option<usize> field on ModelConfig
$modelPath = Join-Path $GooseRepo "crates\goose-provider-types\src\model.rs"
if (Test-Path $modelPath) {
    $m = Get-Content $modelPath -Raw
    $mOk = [bool]($m -match 'pub context_limit: Option<usize>')
    Check "model.rs:44 context_limit is Option<usize>" $mOk "Option field missing"
} else {
    Check "model.rs exists" $false "missing crates/goose-provider-types/src/model.rs"
}

# 3. Notes cover Option/Result/error-as-value
$notesPath = Join-Path (Get-Location) "lab11-notes.md"
$hasNotes = Test-Path $notesPath
Check "lab11-notes.md created" $hasNotes "create lab11-notes.md (steps 1, 3, 4 + homework)"
if ($hasNotes) {
    $notes = Get-Content $notesPath -Raw
    $notesOk = [bool](($notes -match 'Option') -and ($notes -match 'Result') -and ($notes -match '\?'))
    Check "notes discuss Option, Result and ?" $notesOk "missing Option/Result/? discussion"
}

# 4. Scratch parses to Result and matches exhaustively
$srcPath = Join-Path (Get-Location) "lab11-result.rs"
$hasSrc = Test-Path $srcPath
if ($hasSrc) {
    $src = Get-Content $srcPath -Raw
    $srcOk = [bool](($src -match '-> Result<ModelRequest, String>') -and ($src -match 'map_err') -and ($src -match 'RESULT-OK'))
    Check "lab11-result.rs returns Result, uses map_err + marker" $srcOk "one or more required pieces missing"
} else {
    Check "lab11-result.rs created" $false "create lab11-result.rs from lab step 2"
}

# 5. Compiles and prints RESULT-OK
if ($hasSrc) {
    $exe = Join-Path (Get-Location) "lab11-result.exe"
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
        $runOk = [bool](($run -match 'RESULT-OK') -and ($run -match 'ERROR'))
    }
    Check "lab11-result.rs compiles and prints RESULT-OK" $runOk "rustc said: $out"
}

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}