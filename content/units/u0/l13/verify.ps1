# Goose Contributor Academy - Lab check: u0-l13 Error handling
# Run from the folder where you created lab13-errors.rs, config.txt, lab13-notes.md.
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

# 1. thiserror style in the library crate
$errPath = Join-Path $GooseRepo "crates\goose-provider-types\src\errors.rs"
if (Test-Path $errPath) {
    $e = Get-Content $errPath -Raw
    $eOk = [bool](($e -match 'use thiserror::Error;') -and ($e -match '#\[derive\(Error'))
    Check "errors.rs uses thiserror with #[derive(Error)]" $eOk "thiserror usage missing"
} else {
    Check "goose-provider-types/src/errors.rs exists" $false "missing crates/goose-provider-types/src/errors.rs"
}

# 2. anyhow style in app code, including the ? at :125
$tpPath = Join-Path $GooseRepo "crates\goose\src\providers\testprovider.rs"
if (Test-Path $tpPath) {
    $tp = Get-Content $tpPath -Raw
    $tpOk = [bool](($tp -match 'use anyhow::\{anyhow, Result\};') -and ($tp -match 'let content = fs::read_to_string\(file_path\)\?;') -and ($tp -match 'anyhow!\('))
    Check "testprovider.rs uses anyhow::{anyhow, Result} and ?" $tpOk "anyhow usage missing"
} else {
    Check "testprovider.rs exists" $false "missing crates/goose/src/providers/testprovider.rs"
}

# 3. Both crates listed in goose Cargo.toml
$cargoPath = Join-Path $GooseRepo "crates\goose\Cargo.toml"
if (Test-Path $cargoPath) {
    $cargo = Get-Content $cargoPath -Raw
    $cargoOk = [bool](($cargo -match 'anyhow = \{ workspace = true \}') -and ($cargo -match 'thiserror = \{ workspace = true \}'))
    Check "crates/goose/Cargo.toml declares anyhow + thiserror" $cargoOk "dependency lines missing"
} else {
    Check "crates/goose/Cargo.toml exists" $false "missing crates/goose/Cargo.toml"
}

# 4. Notes compare the two styles
$notesPath = Join-Path (Get-Location) "lab13-notes.md"
$hasNotes = Test-Path $notesPath
Check "lab13-notes.md created" $hasNotes "create lab13-notes.md (steps 1, 3 table, 4 + homework)"
if ($hasNotes) {
    $notes = Get-Content $notesPath -Raw
    $notesOk = [bool](($notes -match 'anyhow') -and ($notes -match 'thiserror') -and ($notes -match '\?'))
    Check "notes contrast anyhow vs thiserror and ?" $notesOk "missing anyhow/thiserror/? discussion"
}

# 5. Scratch no longer unwraps or panics
$srcPath = Join-Path (Get-Location) "lab13-errors.rs"
$hasSrc = Test-Path $srcPath
if ($hasSrc) {
    $src = Get-Content $srcPath -Raw
    $clean = (-not ($src -match '\.unwrap\(\)')) -and (-not ($src -match 'panic!'))
    $srcOk = $clean -and ($src -match '-> Result<String, String>') -and ($src -match 'ok_or\(') -and ($src -match 'map_err') -and ($src -match 'ERR-OK')
    Check "lab13-errors.rs: no unwrap/panic; Result + ok_or + map_err + marker" $srcOk "seeded style not fully refactored"
} else {
    Check "lab13-errors.rs created" $false "create lab13-errors.rs from lab step 2/3"
}

# 6. Compiles and prints ERR-OK with both ERROR lines
if ($hasSrc) {
    $exe = Join-Path (Get-Location) "lab13-errors.exe"
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
$errCount = ([regex]::Matches($run, 'ERROR:')).Count
        $runOk = ([bool]($run -match 'ERR-OK') -and ($errCount -ge 1))
    }
    Check "lab13-errors.rs compiles; at least 1 ERROR line and ERR-OK" $runOk "rustc said: $out"
}

# 7. config.txt exists from step 2
$cfgOk = Test-Path (Join-Path (Get-Location) "config.txt")
Check "config.txt created" $cfgOk "create config.txt with gpt-4o:0.7"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}