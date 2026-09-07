# Goose Contributor Academy - Lab check: u0-l09 Lifetimes
# Run from the folder where you created lab09-lifetimes.rs and lab09-notes.md.
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

# 1. LoggingConfig<'a> borrows with a named lifetime
$logPath = Join-Path $GooseRepo "crates\goose\src\logging.rs"
if (Test-Path $logPath) {
    $log = Get-Content $logPath -Raw
    $logOk = [bool](($log -match "struct LoggingConfig<'a>") -and ($log -match "component: &'a str"))
    Check "logging.rs:13 LoggingConfig<'a> with &'a str field" $logOk "struct or field lifetime missing"
} else {
    Check "logging.rs exists" $false "missing crates/goose/src/logging.rs"
}

# 2. resolved_model ties output to &self
$checksPath = Join-Path $GooseRepo "crates\goose\src\checks\mod.rs"
if (Test-Path $checksPath) {
    $chk = Get-Content $checksPath -Raw
    $chkOk = [bool](($chk -match "fn resolved_model<'a>") -and ($chk -match "-> Option<&'a str>"))
    Check "checks/mod.rs:162 resolved_model<'a> -> Option<&'a str>" $chkOk "signature missing"
} else {
    Check "checks/mod.rs exists" $false "missing crates/goose/src/checks/mod.rs"
}

# 3. Notes with a lifetime census (>=3 findings)
$notesPath = Join-Path (Get-Location) "lab09-notes.md"
$hasNotes = Test-Path $notesPath
Check "lab09-notes.md created" $hasNotes "create lab09-notes.md (steps 1, 3, 4 + homework)"
if ($hasNotes) {
    $notes = Get-Content $notesPath -Raw
    $notesOk = [bool](($notes -match 'E0106') -and ($notes -match "'a") -and ($notes -match 'elision'))
    Check "notes discuss E0106, 'a and elision" $notesOk "missing one of E0106/'a/elision"
}

# 4. Scratch has the annotated two-input fn and borrow-storing struct
$srcPath = Join-Path (Get-Location) "lab09-lifetimes.rs"
$hasSrc = Test-Path $srcPath
if ($hasSrc) {
    $src = Get-Content $srcPath -Raw
    $srcOk = [bool](($src -match "fn longer_of<'a>\(x: &'a str, y: &'a str\) -> &'a str") -and ($src -match "struct PromptView<'a>") -and ($src -match "impl<'a> PromptView<'a>") -and ($src -match 'LIFETIME-OK'))
    Check "lab09-lifetimes.rs has longer_of<'a>, PromptView<'a>, impl<'a> + marker" $srcOk "one or more lifetime pieces missing"
} else {
    Check "lab09-lifetimes.rs created" $false "create lab09-lifetimes.rs from lab step 2"
}

# 5. Compiles and prints LIFETIME-OK
if ($hasSrc) {
    $exe = Join-Path (Get-Location) "lab09-lifetimes.exe"
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
        $runOk = [bool](($run -match 'LIFETIME-OK') -and ($run -match 'longer'))
    }
    Check "lab09-lifetimes.rs compiles and prints LIFETIME-OK" $runOk "rustc said: $out"
}

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}