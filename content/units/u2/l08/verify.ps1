# Goose Contributor Academy - Lab check: u2-l08 Self-test & recipes
<# Verifies the run log (honest attempt/skip), the scenario YAML with the
   recipe skeleton, and notes about the suite phases. #>
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

$runlog = Join-Path (Get-Location) "u2-l08-runlog.md"
$notes = Join-Path (Get-Location) "u2-l08-notes.md"
$scenario = Join-Path (Get-Location) "u2-l08-scenario.yaml"

# 1. Run log documents the recipe run attempt honestly
$runOk = $false
if (Test-Path $runlog) {
    $r = Get-Content $runlog -Raw
    $runOk = ($r -match "goose run --recipe") -and ($r -match "goose-self-test")
}
Check "u2-l08-runlog.md records the recipe run" $runOk "command + outcome excerpt or exact blocker"

$runRaw = if (Test-Path $runlog) { Get-Content $runlog -Raw } else { "" }
Check "runlog states a verdict or an explicit blocker" ($runRaw -match "PASS|FAIL|blocked|error|provider|key" ) "success summary or the exact error preventing the run"

# 2. Notes cover suite anatomy
$notesRaw = if (Test-Path $notes) { Get-Content $notes -Raw } else { "" }
Check "u2-l08-notes.md exists" (Test-Path $notes) "record parameters, activities, phases"
Check "notes name parameter keys and defaults" ($notesRaw -match "test_phases|workspace_dir|test_depth") "see goose-self-test.yaml:23"
Check "notes identify the nested-delegation phase" ($notesRaw -match "nested|delegation|CRITICAL") "find which phase carries the CRITICAL test"

# 3. Scenario YAML mirrors the recipe skeleton and interpolates a parameter
$scOk = $false
if (Test-Path $scenario) {
    $s = Get-Content $scenario -Raw
    $scOk = ($s -match "activities") -and ($s -match "parameters") -and ($s -match "prompt") -and ($s -match "\{\{")
}
Check "u2-l08-scenario.yaml skeleton + template vars" $scOk "activities/parameters/prompt with {{ }} placeholders"
$scRaw = if (Test-Path $scenario) { Get-Content $scenario -Raw } else { "" }
Check "scenario guards its phase block" ($scRaw -match "test_phases|\{% if") "use the {% if %} phase guard pattern"
Check "scenario adds the fit_label activity" ($scRaw -match "fit_label|label fitting") "activity line for the feature"

# 4. Clone greps: real recipe anatomy
$gs = Join-Path $GooseRepo "goose-self-test.yaml"
$gsOk = $false
if (Test-Path $gs) {
    $g = Get-Content $gs -Raw
    $gsOk = ($g -match "activities") -and ($g -match "Nested Delegation Prevention Test")
}
Check "clone goose-self-test.yaml has activities + nested delegation" $gsOk "verify GOOSE_REPO path"

$wfr = Join-Path $GooseRepo "workflow_recipes\release_risk_check\recipe.yaml"
Check "clone workflow_recipes recipe exists" (Test-Path $wfr) "release_risk_check/recipe.yaml expected"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}