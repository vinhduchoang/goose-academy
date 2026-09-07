# Goose Contributor Academy - Lab check: u0-l02 Data types
# Run from the folder where you created lab02-tokens.rs and lab02-notes.md.
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

# 1. The goose repo is present and has the token counter
$counterPath = Join-Path $GooseRepo "crates\goose\src\token_counter.rs"
$hasCounter = Test-Path $counterPath
Check "goose repo contains token_counter.rs" $hasCounter "expected crates\goose\src\token_counter.rs under $GooseRepo"

# 2. The MAX_TOKEN_CACHE_SIZE const is exactly what the lesson cited
if ($hasCounter) {
    $line12 = (Get-Content $counterPath)[11]
    $constOk = [bool]($line12 -match 'const MAX_TOKEN_CACHE_SIZE:\s*usize\s*=\s*1_024')
    Check "token_counter.rs:12 declares usize const with digit separator" $constOk "saw: $line12"
}

# 3. count_tokens signature takes &str and returns usize
if ($hasCounter) {
    $line53 = (Get-Content $counterPath)[52]
    $sigOk = [bool]($line53 -match 'fn count_tokens\(&self, text: &str\) -> usize')
    Check "token_counter.rs:53 count_tokens(&str) -> usize" $sigOk "saw: $line53"
}

# 4. Notes file from steps 1-2 exists
$notesPath = Join-Path (Get-Location) "lab02-notes.md"
$hasNotes = Test-Path $notesPath
Check "lab02-notes.md created" $hasNotes "create lab02-notes.md (constants table + type hunt + homework answers)"

# 5. Notes mention the signed constant and the inference finding
if ($hasNotes) {
    $notes = Get-Content $notesPath -Raw
    $mentions = [bool](($notes -match 'ENUM_INIT') -and ($notes -match 'usize'))
    Check "notes discuss ENUM_INIT (the signed const) and usize" $mentions "missing ENUM_INIT or usize discussion"
}

# 6. Scratch exercise exists with the required pieces
$srcPath = Join-Path (Get-Location) "lab02-tokens.rs"
$hasSrc = Test-Path $srcPath
Check "lab02-tokens.rs created" $hasSrc "create lab02-tokens.rs from lab step 3 first"
if ($hasSrc) {
    $src = Get-Content $srcPath -Raw
    $srcOk = [bool](($src -match 'fn fits_in_budget') -and ($src -match 'dbg!') -and ($src -match 'BUDGET-OK'))
    Check "scratch uses fits_in_budget, dbg!, BUDGET-OK marker" $srcOk "missing one of the three required pieces"
}

# 7. It compiles and prints the marker
if ($hasSrc) {
    $exeOk = $false
    $exe = Join-Path (Get-Location) "lab02.exe"
    Remove-Item $exe -ErrorAction SilentlyContinue
    $savedA = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $out = (& rustc --edition 2021 $srcPath -o $exe 2>&1 | Out-String)
    $ErrorActionPreference = $savedA
    if (Test-Path $exe) {
        $savedB = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        $run = (& $exe 2>&1 | Out-String)
        $ErrorActionPreference = $savedB
        $exeOk = [bool]($run -match 'BUDGET-OK')
    }
    Check "lab02-tokens.rs compiles and prints BUDGET-OK" $exeOk "rustc said: $out"
}

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}