# Goose Contributor Academy - Lab check: u0-l07 Ownership
# Run from the folder where you created lab07-moves.rs and lab07-notes.md.
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

# 1. The cited clone sites exist in the real code
$tpPath = Join-Path $GooseRepo "crates\goose\src\providers\testprovider.rs"
if (Test-Path $tpPath) {
    $tp = Get-Content $tpPath -Raw
    $cloneOk = [bool](($tp -match 'msg\.role\.clone\(\)') -and ($tp -match 'message: message\.clone\(\)') -and ($tp -match 'record\.output\.message\.clone\(\)'))
    Check "testprovider.rs contains the three cited clone sites" $cloneOk "one or more clone sites missing"
} else {
    Check "testprovider.rs exists" $false "missing crates/goose/src/providers/testprovider.rs"
}

# 2. Struct-update clone in message.rs:994
$msgPath = Join-Path $GooseRepo "crates\goose-provider-types\src\conversation\message.rs"
if (Test-Path $msgPath) {
    $m = Get-Content $msgPath -Raw
    $suOk = [bool]($m -match '\.\.self\.clone\(\)')
    Check "message.rs uses ..self.clone() struct update" $suOk "struct-update clone missing"
} else {
    Check "conversation/message.rs exists" $false "missing crates/goose-provider-types/src/conversation/message.rs"
}

# 3. Notes file with clone-site explanations
$notesPath = Join-Path (Get-Location) "lab07-notes.md"
$hasNotes = Test-Path $notesPath
Check "lab07-notes.md created" $hasNotes "create lab07-notes.md (steps 1, 2 errors, 3, 4)"
if ($hasNotes) {
    $notes = Get-Content $notesPath -Raw
    $notesOk = [bool](($notes -match 'E0382') -and ($notes -match 'clone') -and ($notes -match 'Copy'))
    Check "notes discuss E0382, clone, Copy" $notesOk "missing E0382/clone/Copy discussion"
}

# 4. Scratch fixes the planted moves
$srcPath = Join-Path (Get-Location) "lab07-moves.rs"
$hasSrc = Test-Path $srcPath
if ($hasSrc) {
    $src = Get-Content $srcPath -Raw
    $srcOk = [bool](($src -match 'publish\(draft\.clone\(\)\)') -and ($src -match 'for l in &labels') -and ($src -match 'MOVES-OK'))
    Check "lab07-moves.rs applies clone + reference fixes + marker" $srcOk "a planted mistake is still unfixed"
} else {
    Check "lab07-moves.rs created" $false "create lab07-moves.rs from lab step 2"
}

# 5. Compiles and prints MOVES-OK
if ($hasSrc) {
    $exe = Join-Path (Get-Location) "lab07-moves.exe"
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
        $runOk = [bool](($run -match 'MOVES-OK') -and ($run -match 'labels alive'))
    }
    Check "lab07-moves.rs compiles and prints MOVES-OK" $runOk "rustc said: $out"
}

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}