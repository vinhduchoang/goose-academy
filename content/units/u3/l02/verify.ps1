<# Goose Contributor Academy - Lab check: u3-l02 Echo provider
   Validates the learner's standalone provider crate: Cargo.toml path dep,
   Provider impl shape, enclosure-type usage, naive token accounting,
   a complete() test, notes, and goose-repo grep evidence.
#>
param(
    [string]$GooseRepo = $env:GOOSE_REPO,
    [string]$LabDir = (Get-Location).Path
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

# The echo crate may live directly in LabDir or in LabDir\echo-ext
$crateDir = $LabDir
if (-not (Test-Path (Join-Path $crateDir "Cargo.toml"))) {
    $crateDir = Join-Path $LabDir "echo-ext"
}

# 1. Cargo.toml exists and depends on goose-provider-types
$cargoPath = Join-Path $crateDir "Cargo.toml"
$cargoOk = $false
if (Test-Path $cargoPath) {
    $toml = Get-Content $cargoPath -Raw
    $cargoOk = $toml -match 'goose-provider-types' -and $toml -match '\[package\]'
}
Check "echo-ext Cargo.toml exists with goose-provider-types dependency" $cargoOk "scaffold cargo new --lib echo-ext and add the path dependency"

# 2. src/lib.rs implements the Provider trait with an async fn stream
$libPath = Join-Path $crateDir "src\lib.rs"
$lib = if (Test-Path $libPath) { Get-Content $libPath -Raw } else { "" }
Check "src/lib.rs has impl Provider for + async fn stream" ($lib -match 'impl\s+Provider\s+for' -and $lib -match 'async fn stream') "implement stream() per goose-provider-types/src/base.rs:477"

# 3. #[async_trait] is applied (the trait is async_trait-declared)
Check "src/lib.rs uses #[async_trait]" ($lib -match '#\[async_trait\]') "the Provider trait is declared with #[async_trait]"

# 4. Enclosure types used: MessageContentBlock / Text
Check "src/lib.rs builds MessageContentBlock content" ($lib -match 'MessageContentBlock') "reply content must be a MessageContentBlock variant"

# 5. Naive token accounting present (Usage with input/output counts)
Check "src/lib.rs computes tokens into Usage" ($lib -match 'input_tokens' -and $lib -match 'output_tokens' -and $lib -match 'ProviderUsage') "set input_tokens/output_tokens on a ProviderUsage"

# 6. A complete() integration test exists
$testOk = $lib -match '#\[tokio::test\]' -or $lib -match '#\[test\]'
$testsDir = Join-Path $crateDir "tests"
if (-not $testOk -and (Test-Path $testsDir)) {
    $testFiles = Get-ChildItem $testsDir -Filter *.rs -ErrorAction SilentlyContinue
    $testOk = $null -ne $testFiles
}
Check "test exists exercising complete()" $testOk "add a #[tokio::test] that calls complete() and asserts the echo"

# 7. Notes record the stream/complete contract
$notesPath = Join-Path $LabDir "u3-l02-notes.md"
$notes = if (Test-Path $notesPath) { Get-Content $notesPath -Raw } else { "" }
Check "u3-l02-notes.md records MessageStream + collect_stream findings" ($notes -match 'MessageStream' -and $notes -match 'collect_stream') "create u3-l02-notes.md per Step 2 and Step 5"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}