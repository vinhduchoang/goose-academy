# Goose Contributor Academy - Lab check: u0-l12 Generics & traits
# Run from the folder where you created lab12-generics.rs and lab12-notes.md.
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

# 1. Provider trait with Send + Sync supertraits
$basePath = Join-Path $GooseRepo "crates\goose-provider-types\src\base.rs"
if (Test-Path $basePath) {
    $b = Get-Content $basePath -Raw
    $traitOk = [bool](($b -match 'pub trait Provider: Send \+ Sync') -and ($b -match 'async fn stream\(') -and ($b -match 'async fn complete\('))
    Check "base.rs:464 Provider: Send + Sync with stream/complete" $traitOk "trait shape missing"
} else {
    Check "goose-provider-types/src/base.rs exists" $false "missing crates/goose-provider-types/src/base.rs"
}

# 2. MessageStream is a boxed dyn Stream
if (Test-Path $basePath) {
    $lines = Get-Content $basePath
    $ms = $lines[326]
    $ms2 = $lines[327]
    $msOk = [bool](($ms -match 'pub type MessageStream = Pin') -and ($ms2 -match 'Box<dyn Stream<Item = Result<'))
    Check "base.rs:327 MessageStream = Pin<Box<dyn Stream<...>>" $msOk "saw: $ms / $ms2"
}

# 3. A real implementor of the trait
$tpPath = Join-Path $GooseRepo "crates\goose\src\providers\testprovider.rs"
if (Test-Path $tpPath) {
    $tp = Get-Content $tpPath -Raw
    $implOk = [bool](($tp -match 'impl Provider for TestProvider') -and ($tp -match '#\[async_trait\]'))
    Check "testprovider.rs:168 impl Provider for TestProvider" $implOk "trait impl missing"
} else {
    Check "testprovider.rs exists" $false "missing crates/goose/src/providers/testprovider.rs"
}

# 4. Notes cover the trait dissections
$notesPath = Join-Path (Get-Location) "lab12-notes.md"
$hasNotes = Test-Path $notesPath
Check "lab12-notes.md created" $hasNotes "create lab12-notes.md (steps 1, 3, 4 + homework)"
if ($hasNotes) {
    $notes = Get-Content $notesPath -Raw
    $notesOk = [bool](($notes -match 'Send') -and ($notes -match 'sync') -and ($notes -match 'dyn Provider'))
    Check "notes mention Send, Sync and dyn Provider" $notesOk "missing trait-object discussion"
}

# 5. Scratch implements a trait + generic bounds
$srcPath = Join-Path (Get-Location) "lab12-generics.rs"
$hasSrc = Test-Path $srcPath
if ($hasSrc) {
    $src = Get-Content $srcPath -Raw
    $srcOk = [bool](($src -match 'fn summarize<T: Display>') -and ($src -match 'trait Named') -and ($src -match 'impl Named for ProviderStub') -and ($src -match 'fn labeled\(who: impl AsRef<str>\)') -and ($src -match 'GENERIC-OK'))
    Check "lab12-generics.rs has summarize<T>, Named trait, impl, impl AsRef<str> + marker" $srcOk "one or more required pieces missing"
} else {
    Check "lab12-generics.rs created" $false "create lab12-generics.rs from lab step 2"
}

# 6. Compiles and prints GENERIC-OK
if ($hasSrc) {
    $exe = Join-Path (Get-Location) "lab12-generics.exe"
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
        $runOk = [bool](($run -match 'GENERIC-OK') -and ($run -match 'hi, I am test'))
    }
    Check "lab12-generics.rs compiles and prints GENERIC-OK" $runOk "rustc said: $out"
}

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}