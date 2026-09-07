# Goose Contributor Academy - Lab check: u0-l03 Strings & compound types
# Run from the folder where you created lab03-board.rs, lab03-fixes.rs, lab03-notes.md.
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

# 1. Prompts folder exists in the goose repo
$promptsOk = Test-Path (Join-Path $GooseRepo "crates\goose\src\prompts\plan.md")
Check "goose prompts/plan.md exists" $promptsOk "expected crates\goose\src\prompts\plan.md under $GooseRepo"

# 2. include_dir embeds the prompts at compile time
$ptPath = Join-Path $GooseRepo "crates\goose\src\prompt_template.rs"
$hasPT = Test-Path $ptPath
if ($hasPT) {
    $pt = Get-Content $ptPath -Raw
    $embedOk = [bool]($pt -match 'include_dir!\("\$CARGO_MANIFEST_DIR/src/prompts"\)')
    Check "prompt_template.rs embeds prompts via include_dir!" $embedOk "missing include_dir! line"
}

# 3. TEMPLATE_REGISTRY is &[(&str, &str)]
if ($hasPT) {
    $reg = (Get-Content $ptPath)[8]
    $regOk = [bool]($reg -match 'TEMPLATE_REGISTRY.*&\[\(&str, &str\)\]')
    Check "TEMPLATE_REGISTRY: borrowed slice of (&str, &str) tuples" $regOk "saw: $reg"
}

# 4. Notes file exists and covers the ownership rules
$notesPath = Join-Path (Get-Location) "lab03-notes.md"
$hasNotes = Test-Path $notesPath
Check "lab03-notes.md created" $hasNotes "create lab03-notes.md (4 fix rules + registry answers)"
if ($hasNotes) {
    $notes = Get-Content $notesPath -Raw
    $notesOk = [bool](($notes -match 'borrow') -and ($notes -match '&str'))
    Check "notes explain borrowing and &str ownership" $notesOk "missing borrow/&str discussion"
}

# 5. Board exercise compiles and prints BOARD-OK
$boardPath = Join-Path (Get-Location) "lab03-board.rs"
$hasBoard = Test-Path $boardPath
if ($hasBoard) {
    $exe = Join-Path (Get-Location) "lab03-board.exe"
    Remove-Item $exe -ErrorAction SilentlyContinue
    $savedA = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $out = (& rustc --edition 2021 $boardPath -o $exe 2>&1 | Out-String)
    $ErrorActionPreference = $savedA
    $boardOk = $false
    if (Test-Path $exe) {
        $savedB = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        $run = (& $exe 2>&1 | Out-String)
        $ErrorActionPreference = $savedB
        $boardOk = [bool](($run -match 'BOARD-OK') -and ($run -match 'pieces:'))
    }
    Check "lab03-board.rs compiles and prints BOARD-OK" $boardOk "rustc said: $out"
} else {
    Check "lab03-board.rs created" $false "create lab03-board.rs from lab step 2"
}

# 6. Fixes file compiles and prints FIXES-OK
$fixesPath = Join-Path (Get-Location) "lab03-fixes.rs"
$hasFixes = Test-Path $fixesPath
if ($hasFixes) {
    $exe2 = Join-Path (Get-Location) "lab03-fixes.exe"
    Remove-Item $exe2 -ErrorAction SilentlyContinue
    $savedA2 = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $out2 = (& rustc --edition 2021 $fixesPath -o $exe2 2>&1 | Out-String)
    $ErrorActionPreference = $savedA2
    $fixesOk = $false
    if (Test-Path $exe2) {
        $savedB2 = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        $run2 = (& $exe2 2>&1 | Out-String)
        $ErrorActionPreference = $savedB2
        $fixesOk = [bool]($run2 -match 'FIXES-OK')
    }
    Check "lab03-fixes.rs (4 fixed mismatches) compiles and prints FIXES-OK" $fixesOk "rustc said: $out2"
} else {
    Check "lab03-fixes.rs created" $false "create lab03-fixes.rs from lab step 3"
}

# 7. Fixes file uses the correct signatures
if ($hasFixes) {
    $src = Get-Content $fixesPath -Raw
    $sigOk = [bool](($src -match "fn greeting\(\) -> &'static str") -and ($src -match 'fn count_lines\(text: &str\)') -and ($src -match 'fn append_marker\(s: &mut String\)'))
    Check "fixes use &str return, &str param, &mut String param" $sigOk "one or more signatures still planted"
}

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}