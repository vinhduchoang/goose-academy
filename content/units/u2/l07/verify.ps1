# Goose Contributor Academy - Lab check: u2-l07 Feature mini-cycle
<# Verifies proposal structure, scratch impl + tests, scratch self-test
   recipe, and the plan notes. Plus clone greps for the real recipe. #>
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

$scratch = Join-Path (Get-Location) "u2-l07-scratch"
$proposal = Join-Path (Get-Location) "u2-l07-proposal.md"
$recipe = Join-Path (Get-Location) "u2-l07-selftest.yaml"
$plan = Join-Path (Get-Location) "u2-l07-selftest-plan.md"

# 1. Proposal follows the feature template
$propOk = $false
if (Test-Path $proposal) {
    $t = Get-Content $proposal -Raw
    $propOk = ($t -match "What problem would this solve") -and ($t -match "good outcome") -and ($t -match "approaches")
}
Check "u2-l07-proposal.md mirrors feature_request.md" $propOk "problem / outcome / approaches sections"

# 2. Scratch impl is char-boundary safe
$libOk = $false
if (Test-Path (Join-Path $scratch "src\lib.rs")) {
    $l = Get-Content (Join-Path $scratch "src\lib.rs") -Raw
    $libOk = ($l -match "fn fit_label") -and ($l -match "chars\(\)")
}
Check "src/lib.rs has char-safe fit_label" $libOk "chars().take(max) not byte slicing"

# 3. Outcome tests exist in tests/ folder
$testsOk = $false
if (Test-Path (Join-Path $scratch "tests\fit_label_test.rs")) {
    $t2 = Get-Content (Join-Path $scratch "tests\fit_label_test.rs") -Raw
    $testsOk = ($t2 -match "fit_label") -and ($t2 -match "#\[test\]")
}
Check "tests/fit_label_test.rs asserts the outcome" $testsOk "cover exact-fit, truncation, multibyte safety"

# 4. Scratch self-test recipe has the real skeleton
$recipeOk = $false
if (Test-Path $recipe) {
    $r = Get-Content $recipe -Raw
    $recipeOk = ($r -match "version") -and ($r -match "title") -and ($r -match "activities") -and ($r -match "instructions") -and ($r -match "prompt")
}
Check "u2-l07-selftest.yaml has recipe skeleton" $recipeOk "version/title/activities/instructions/prompt keys"

# 5. Plan notes cover the real recipe mapping and the run command
$planOk = $false
if (Test-Path $plan) {
    $p = Get-Content $plan -Raw
    $planOk = ($p -match "goose-self-test\.yaml") -and ($p -match "goose run --recipe") -and ($p -match "rebuild|build")
}
Check "u2-l07-selftest-plan.md maps phase + run command" $planOk "phase choice, goosing run --recipe, rebuild rationale"

# 6. Clone greps: rule, real recipe, CLI flag
$ag = Join-Path $GooseRepo "AGENTS.md"
$agOk = $false
if (Test-Path $ag) { $agOk = (Get-Content $ag -Raw) -match "goose run --recipe goose-self-test.yaml" }
Check "clone AGENTS.md has the self-test update rule" $agOk "verify GOOSE_REPO path"

$gs = Join-Path $GooseRepo "goose-self-test.yaml"
Check "clone has root goose-self-test.yaml" (Test-Path $gs) "expected recipe file"

$cli = Join-Path $GooseRepo "crates\goose-cli\src\cli.rs"
$cliOk = $false
if (Test-Path $cli) { $cliOk = (Get-Content $cli -Raw) -match "long = `"recipe`"" }
Check "clone cli.rs defines --recipe" $cliOk "expected long = `"recipe`""

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}