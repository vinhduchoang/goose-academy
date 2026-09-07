# Goose Contributor Academy - Lab check: u2-l05 Clippy cleanups
<# Verifies the planted warnings were fixed at the source and the notes map
   lints to policy. Cheap greps; no builds. #>
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

$scratch = Join-Path (Get-Location) "u2-l05-scratch"
$notes = Join-Path (Get-Location) "u2-l05-notes.md"

$mainRaw = ""
$mainOk = Test-Path (Join-Path $scratch "src\main.rs")
if ($mainOk) { $mainRaw = Get-Content (Join-Path $scratch "src\main.rs") -Raw }

# 1. string_slice candidate removed (no byte slicing on a String)
Check "no `&full_name[0..2]` remains" ($mainOk -and ($mainRaw -notmatch "&full_name")) "use get(..) with a documented fallback"

# 2. get(..) replacement present
Check "get(0..2) replacement present" ($mainOk -and ($mainRaw -match "\.get\(0\.\.2\)")) "use .get(0..2) plus unwrap_or decision"

# 3. needless comparison removed
Check "no `is_dirty == true` remains" ($mainOk -and ($mainRaw -notmatch "== true")) "use the bare boolean"

# 4. redundant clone removed (plain copy)
Check "no `cached.clone()` remains" ($mainOk -and ($mainRaw -notmatch "cached\.clone")) "plain copy of the Copy value"

# 5. Notes map lints to policy and the gate
$notesRaw = if (Test-Path $notes) { Get-Content $notes -Raw } else { "" }
Check "notes exist" (Test-Path $notes) "u2-l05-notes.md required"
Check "notes name the three lint classes" (($notesRaw -match "string_slice") -and ($notesRaw -match "clippy|needless|redundant") ) "record lint names emitted"
Check "notes discuss -D warnings gate" ($notesRaw -match "-D warnings") "explain what --all-targets -- -D warnings does"

# 6. Clone policy greps
$rootToml = Join-Path $GooseRepo "Cargo.toml"
$policyOk = $false
if (Test-Path $rootToml) {
    $t = Get-Content $rootToml -Raw
    $policyOk = ($t -match '\[workspace\.lints\.clippy\]') -and ($t -match 'string_slice\s*=\s*"warn"')
}
Check "clone root Cargo.toml warns on string_slice" $policyOk "verify GOOSE_REPO path"

$jf = Join-Path $GooseRepo "Justfile"
$jfOk = $false
if (Test-Path $jf) { $jfOk = (Get-Content $jf -Raw) -match "--all-targets -- -D warnings" }
Check "clone Justfile clippy gate uses -D warnings" $jfOk "expected cargo clippy --all-targets -- -D warnings"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}