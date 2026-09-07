# Goose Contributor Academy - Lab check: u0-l15 Arc/Mutex/async streams
# Run from the folder containing your lab15-fakeprovider\ cargo project.
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

# 1. SharedProvider double-Arc type in agents/types.rs
$typesPath = Join-Path $GooseRepo "crates\goose\src\agents\types.rs"
if (Test-Path $typesPath) {
    $t = Get-Content $typesPath -Raw
    $tOk = [bool]($t -match 'pub type SharedProvider = Arc<Mutex<Option<Arc<dyn Provider>>>>;')
    Check "types.rs:7 SharedProvider = Arc<Mutex<Option<Arc<dyn Provider>>>>" $tOk "type alias missing"
} else {
    Check "agents/types.rs exists" $false "missing crates/goose/src/agents/types.rs"
}

# 2. TestProvider holds lock-guarded records and an #[async_trait] impl
$tpPath = Join-Path $GooseRepo "crates\goose\src\providers\testprovider.rs"
if (Test-Path $tpPath) {
    $tp = Get-Content $tpPath -Raw
    $tpOk = [bool](($tp -match 'records: Arc<Mutex<HashMap<String, TestRecord>>>') -and ($tp -match '#\[async_trait\]') -and ($tp -match 'let records = self\.records\.lock\(\)\.unwrap\(\);'))
    Check "testprovider.rs has Arc<Mutex<HashMap>>, async_trait, lock().unwrap()" $tpOk "one or more pieces missing"
} else {
    Check "testprovider.rs exists" $false "missing crates/goose/src/providers/testprovider.rs"
}

# 3. Box::pin single-message stream in base.rs
$basePath = Join-Path $GooseRepo "crates\goose-provider-types\src\base.rs"
if (Test-Path $basePath) {
    $b = Get-Content $basePath -Raw
    $bOk = [bool](($b -match 'Box::pin\(stream\)') -and ($b -match 'futures::stream::once'))
    Check "base.rs:457 wraps a once-stream via Box::pin" $bOk "stream helper missing"
} else {
    Check "base.rs exists" $false "missing crates/goose-provider-types/src/base.rs"
}

# 4. The cargo project exists with tokio + futures + async-trait
$proj = Join-Path (Get-Location) "lab15-fakeprovider"
$hasProj = (Test-Path $proj) -and (Test-Path (Join-Path $proj "Cargo.toml"))
Check "lab15-fakeprovider\Cargo.toml created" $hasProj "run cargo new + cargo add tokio futures async-trait"
if ($hasProj) {
    $cargo = Get-Content (Join-Path $proj "Cargo.toml") -Raw
    $depsOk = [bool](($cargo -match 'tokio') -and ($cargo -match 'futures') -and ($cargo -match 'async-trait'))
    Check "Cargo.toml declares tokio, futures, async-trait" $depsOk "dependencies missing"
}

# 5. main.rs implements trait + lock state + async stream + marker
$mainPath = Join-Path $proj "src\main.rs"
if (Test-Path $mainPath) {
    $src = Get-Content $mainPath -Raw
    $srcOk = [bool](($src -match 'trait MiniProvider') -and ($src -match 'impl MiniProvider for EchoProvider') -and ($src -match 'Arc<Mutex<HashMap') -and ($src -match 'async fn stream') -and ($src -match 'Box::pin\(stream\)') -and ($src -match 'FAKE-OK'))
    Check "main.rs has trait, impl, Arc<Mutex>, async stream, Box::pin + marker" $srcOk "one or more pieces missing"
} else {
    Check "lab15-fakeprovider\src\main.rs exists" $false "replace src/main.rs per lab step 2"
}

# 6. Notes contain the mapping table and the Send lesson
$notesPath = Join-Path (Get-Location) "lab15-notes.md"
$hasNotes = Test-Path $notesPath
Check "lab15-notes.md created" $hasNotes "create lab15-notes.md (steps 1, 3, 4 + homework)"
if ($hasNotes) {
    $notes = Get-Content $notesPath -Raw
    $notesOk = [bool](($notes -match 'MutexGuard') -and ($notes -match 'stream_from_single_message') -and ($notes -match 'Send'))
    Check "notes cover MutexGuard, Send and the mapping table" $notesOk "missing async-state discussion"
}

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}