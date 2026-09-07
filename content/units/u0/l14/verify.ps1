# Goose Contributor Academy - Lab check: u0-l14 Serde
# Run from the folder containing your lab14-serde\ cargo project.
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

# 1. Real serde attributes on ModelConfig
$modelPath = Join-Path $GooseRepo "crates\goose-provider-types\src\model.rs"
if (Test-Path $modelPath) {
    $m = Get-Content $modelPath -Raw
    $mOk = [bool](($m -match '#\[derive\(Debug, Clone, Serialize\)\]') -and ($m -match '#\[serde\(skip\)\]') -and ($m -match 'serde\(default, skip_serializing_if'))
    Check "model.rs has Serialize derive, serde(skip), serde(default, skip_serializing_if)" $mOk "one or more attributes missing"
} else {
    Check "goose-provider-types/src/model.rs exists" $false "missing crates/goose-provider-types/src/model.rs"
}

# 2. rename_all camelCase on Message
$msgPath = Join-Path $GooseRepo "crates\goose-provider-types\src\conversation\message.rs"
if (Test-Path $msgPath) {
    $g = Get-Content $msgPath -Raw
    $gOk = [bool]($g -match 'serde\(rename_all = "camelCase"\)')
    Check "message.rs:961 renames wire keys to camelCase" $gOk "rename_all missing"
} else {
    Check "conversation/message.rs exists" $false "missing crates/goose-provider-types/src/conversation/message.rs"
}

# 3. serde tag on the SuccessCheck enum
$typesPath = Join-Path $GooseRepo "crates\goose\src\agents\types.rs"
if (Test-Path $typesPath) {
    $t = Get-Content $typesPath -Raw
    $tOk = [bool]($t -match 'serde\(tag = "type"\)')
    Check "types.rs:60 tags SuccessCheck with type" $tOk "serde tag missing"
} else {
    Check "agents/types.rs exists" $false "missing crates/goose/src/agents/types.rs"
}

# 4. The cargo project exists with deps declared
$proj = Join-Path (Get-Location) "lab14-serde"
$hasProj = (Test-Path $proj) -and (Test-Path (Join-Path $proj "Cargo.toml"))
Check "lab14-serde\Cargo.toml created" $hasProj "run cargo new lab14-serde + cargo add serde serde_json"
if ($hasProj) {
    $cargo = Get-Content (Join-Path $proj "Cargo.toml") -Raw
    $depsOk = [bool](($cargo -match 'serde') -and ($cargo -match 'serde_json'))
    Check "Cargo.toml declares serde and serde_json" $depsOk "dependencies missing"
}

# 5. ModelConfig-shaped struct with the attributes
$mainPath = Join-Path $proj "src\main.rs"
if (Test-Path $mainPath) {
    $src = Get-Content $mainPath -Raw
    $srcOk = [bool](($src -match '#\[derive\([^\]]*Serialize[^\]]*Deserialize[^\]]*\)\]') -and ($src -match 'camelCase') -and ($src -match '#\[serde\(skip\)\]') -and ($src -match 'serde\(default, skip_serializing_if = "Option::is_none"\)') -and ($src -match 'SERDE-OK'))
    Check "main.rs has derive + rename_all + skip + default + marker" $srcOk "one or more pieces missing in main.rs"
} else {
    Check "lab14-serde\src\main.rs exists" $false "replace src/main.rs per lab step 2"
}

# 6. Notes record the round-trip observations
$notesPath = Join-Path (Get-Location) "lab14-notes.md"
$hasNotes = Test-Path $notesPath
Check "lab14-notes.md created" $hasNotes "create lab14-notes.md (steps 1, 3, 4, 5 + homework)"
if ($hasNotes) {
    $notes = Get-Content $notesPath -Raw
    $notesOk = [bool](($notes -match 'apiKey') -and ($notes -match 'default') -and ($notes -match 'camelCase'))
    Check "notes discuss apiKey omission, default and camelCase" $notesOk "missing round-trip observations"
}

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}