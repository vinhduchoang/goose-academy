# Goose Contributor Academy - Lab check: u0-l10 Structs + impl
# Run from the folder where you created lab10-config.rs and lab10-notes.md.
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

# 1. Real ModelConfig struct with pub fields
$modelPath = Join-Path $GooseRepo "crates\goose-provider-types\src\model.rs"
if (Test-Path $modelPath) {
    $m = Get-Content $modelPath -Raw
    $mOk = [bool](($m -match 'pub struct ModelConfig') -and ($m -match 'pub model_name: String') -and ($m -match 'pub toolshim: bool'))
    Check "model.rs:41 ModelConfig with public fields" $mOk "struct or fields missing"
} else {
    Check "goose-provider-types/src/model.rs exists" $false "missing crates/goose-provider-types/src/model.rs"
}

# 2. new() constructor and builder-style method
if (Test-Path $modelPath) {
    $m = Get-Content $modelPath -Raw
    $m2Ok = [bool](($m -match 'pub fn new\(model_name: impl AsRef<str>\) -> Self') -and ($m -match 'pub fn with_canonical_limits\(mut self, provider_name: &str\) -> Self'))
    Check "model.rs has new() associated fn and mut-self builder" $m2Ok "constructor or builder signature missing"
}

# 3. TokenCounter keeps its fields private (contrast case)
$counterPath = Join-Path $GooseRepo "crates\goose\src\token_counter.rs"
if (Test-Path $counterPath) {
    $c = Get-Content $counterPath -Raw
    $cOk = [bool](($c -match 'pub struct TokenCounter') -and ($c -notmatch 'pub tokenizer') -and ($c -notmatch 'pub token_cache') -and ($c -match 'token_cache'))
    Check "TokenCounter fields stay private" $cOk "expected token_cache present and not pub"
} else {
    Check "token_counter.rs exists" $false "missing crates/goose/src/token_counter.rs"
}

# 4. Notes cover structs, visibilities, builder
$notesPath = Join-Path (Get-Location) "lab10-notes.md"
$hasNotes = Test-Path $notesPath
Check "lab10-notes.md created" $hasNotes "create lab10-notes.md (steps 1, 3, 4 + homework)"
if ($hasNotes) {
    $notes = Get-Content $notesPath -Raw
    $notesOk = [bool](($notes -match 'mut self') -and ($notes -match 'private') -and ($notes -match 'pub'))
    Check "notes discuss mut self, pub, private" $notesOk "missing visibility/builder discussion"
}

# 5. Scratch struct mirrors ModelConfig shape
$srcPath = Join-Path (Get-Location) "lab10-config.rs"
$hasSrc = Test-Path $srcPath
if ($hasSrc) {
    $src = Get-Content $srcPath -Raw
    $srcOk = [bool](($src -match 'pub struct AgentConfig') -and ($src -match 'pub fn new\(model_name: impl AsRef<str>\) -> Self') -and ($src -match 'pub fn with_context_limit\(mut self') -and ($src -match 'STRUCT-OK'))
    Check "lab10-config.rs has AgentConfig, new(), with_* builders + marker" $srcOk "one or more required pieces missing"
} else {
    Check "lab10-config.rs created" $false "create lab10-config.rs from lab step 2"
}

# 6. Compiles and prints STRUCT-OK
if ($hasSrc) {
    $exe = Join-Path (Get-Location) "lab10-config.exe"
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
        $runOk = [bool](($run -match 'STRUCT-OK') -and ($run -match 'base defaults'))
    }
    Check "lab10-config.rs compiles and prints STRUCT-OK" $runOk "rustc said: $out"
}

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}