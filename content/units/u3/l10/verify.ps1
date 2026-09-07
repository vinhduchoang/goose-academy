<# Goose Contributor Academy - Lab check: u3-l10 Capstone
   Verifies the capstone extension structure: Cargo.toml (or plugin
   manifest), src/, tests/, README.md, docs/design.md, manifest/config,
   QA report with real gate markers, and goose-repo grep evidence.
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

# The capstone dir may live directly in LabDir or in LabDir\capstone-ext
$capDir = $LabDir
if (-not (Test-Path (Join-Path $capDir "src")) -and (Test-Path (Join-Path $LabDir "capstone-ext"))) {
    $capDir = Join-Path $LabDir "capstone-ext"
}

# 1. Manifest or Cargo.toml present
$isCrate = Test-Path (Join-Path $capDir "Cargo.toml")
$isPlugin = Test-Path (Join-Path $capDir "plugin.json")
$isConfig = Test-Path (Join-Path $capDir "config.example.yaml")
Check "capstone has Cargo.toml, plugin.json, or config.example.yaml" ($isCrate -or $isPlugin -or $isConfig) "scaffold one route from Step 2"

# 2. Implementation exists: src dir with .rs or commands/skills dirs
$srcRs = @()
if (Test-Path (Join-Path $capDir "src")) { $srcRs = Get-ChildItem (Join-Path $capDir "src") -Filter *.rs -ErrorAction SilentlyContinue }
$hasCommands = Test-Path (Join-Path $capDir "commands")
$hasSkills = Test-Path (Join-Path $capDir "skills")
Check "implementation present (src/*.rs, commands/, or skills/)" (($srcRs.Count -ge 1) -or $hasCommands -or $hasSkills) "implement your workflow surface"

# 3. tests/ directory with at least one test file
$testsDir = Join-Path $capDir "tests"
$testFiles = @()
if (Test-Path $testsDir) { $testFiles = Get-ChildItem $testsDir -Filter *.rs -ErrorAction SilentlyContinue }
$inline = $false
if ($srcRs.Count -ge 1) {
    foreach ($s in $srcRs) { if ((Get-Content $s.FullName -Raw) -match '#\[test\]') { $inline = $true } }
}
Check "tests exist (tests/*.rs or inline #[test])" (($testFiles.Count -ge 1) -or $inline) "add the tests from Step 4"

# 4. docs/design.md with problem + security posture
$designPath = Join-Path $capDir "docs\design.md"
$design = if (Test-Path $designPath) { Get-Content $designPath -Raw } else { "" }
Check "docs/design.md documents problem + security model" `
    ($design -match 'problem|Problem' -and $design -match 'secur|Security') `
    "create docs/design.md from Step 1"

# 5. README.md with install + tools table
$readmePath = Join-Path $capDir "README.md"
$readme = if (Test-Path $readmePath) { Get-Content $readmePath -Raw } else { "" }
Check "README.md covers install + tool/command listing" `
    ($readme -match 'install|Install|extensions|plugin install' -and $readme -match 'tool|Tool|command|Command') `
    "write README.md per Step 5"

# 6. QA report exists with honest gate markers
$qaPath = Join-Path $capDir "qa-report.txt"
$qa = if (Test-Path $qaPath) { Get-Content $qaPath -Raw } else { "" }
Check "qa-report.txt exists with gate markers" `
    ($qa -match 'CLIPPY-RUN-DONE|GATES-RUN-DONE|test result:') `
    "record fmt/clippy/test (or plugin validations) from Step 5"

# 7. Failure-branch evidence in implementation
$implText = ""
foreach ($s in $srcRs) { $implText += (Get-Content $s.FullName -Raw) }
Check "failure branches handled (INVALID_PARAMS / ErrorData / Err)" `
    ($implText -match 'INVALID_PARAMS|INVALID_REQUEST|ErrorData|Err\(') `
    "harden inputs per l07 discipline"

# 8. Goose-repo evidence: surface reference files exist upstream
$mcpRef = Select-String -Path (Join-Path $GooseRepo "crates\goose-mcp\src\memory\mod.rs") -Pattern 'tool_router' -ErrorAction SilentlyContinue
Check "goose repo: memory server reference present" ($null -ne $mcpRef) "grep crates/goose-mcp/src/memory/mod.rs"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}