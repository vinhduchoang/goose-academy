# Goose Contributor Academy - Lab check: u1-l01 Workspace graph
# Run from any directory. Validates cargo metadata graph work + notes artifact.
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

# 1. goose-sdk-types is a sink: its manifest declares no workspace deps
$sdkToml = Get-Content (Join-Path $GooseRepo "crates\goose-sdk-types\Cargo.toml") -Raw -ErrorAction SilentlyContinue
Check "crates/goose-sdk-types/Cargo.toml exists" ($null -ne $sdkToml) "missing file in checkout"
if ($sdkToml -and $sdkToml -match "\[dependencies\]" -and $sdkToml -notmatch "goose-provider-types|goose-sdk-types\s*=") {
    Check "goose-sdk-types declares only external (non-workspace) deps" $true "n/a"
} else {
    Check "goose-sdk-types declares only external (non-workspace) deps" $false "re-read the manifest; expect serde/schemars/acp only"
}

# 2. Provider trait lives in goose-provider-types (the sink-side definition)
$traitLine = Select-String -Path (Join-Path $GooseRepo "crates\goose-provider-types\src\base.rs") -Pattern '^pub trait Provider: Send \+ Sync' -ErrorAction SilentlyContinue
Check "Provider trait defined in goose-provider-types/src/base.rs" ($null -ne $traitLine) "expected 'pub trait Provider: Send + Sync'"

# 3. goose re-exports the conversation datamodel from goose-providers
$reexport = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\lib.rs") -Pattern 'pub use goose_providers::conversation' -ErrorAction SilentlyContinue
Check "goose/src/lib.rs re-exports goose_providers::conversation" ($null -ne $reexport) "expected re-export in pub mod conversation"

# 4. DOT artifact exists and is non-trivial
$dot = Test-Path (Join-Path (Get-Location) "l01-graph.dot")
$dotOk = $false
if ($dot) {
    $content = Get-Content (Join-Path (Get-Location) "l01-graph.dot") -Raw
    $dotOk = ($content -match 'digraph') -and ($content -match 'goose-provider-types') -and ($content -match 'goose-providers')
}
Check "l01-graph.dot mentions provider-types and goose-providers" $dotOk "run Step 2 and save l01-graph.dot"

# 5. Notes artifact answers the three questions with evidence
$notesOk = $false
if (Test-Path (Join-Path (Get-Location) "l01-workspace-notes.md")) {
    $notes = Get-Content (Join-Path (Get-Location) "l01-workspace-notes.md") -Raw
    $notesOk = ($notes -match 'goose-provider-types') -and ($notes -match 'goose-cli') -and
               ($notes -match 'lib\.rs') -and ($notes -match 'vendor/v8')
}
Check "l01-workspace-notes.md contains edge evidence + vendor/v8 answer" $notesOk "complete Steps 3-4 first"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}