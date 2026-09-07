# Goose Contributor Academy - Lab check: u2-l01 Contribution operations
<# Verifies the triage notes and the template-conformant issue the learner
   filed, plus cheap greps in the real clone. #>
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

# 1. Triage notes exist with all three historical issues
$triage = Join-Path (Get-Location) "u2-l01-triage.md"
$triageOk = $false
if (Test-Path $triage) {
    $t = Get-Content $triage -Raw
    $triageOk = ($t -match "#4632") -and ($t -match "#9586") -and ($t -match "#10482")
}
Check "u2-l01-triage.md covers #4632, #9586, #10482" $triageOk "one issue per line with status + reason"

# 2. Triage uses valid status vocabulary
$statusOk = $false
if (Test-Path $triage) {
    $t = Get-Content $triage -Raw
    $statusOk = $t -match "Inbox|Needs info|Accepted|Ready|Done"
}
Check "triage uses board status vocabulary" $statusOk "use one of Inbox / Needs info / Accepted / Ready / Done per line"

# 3. New issue file exists and follows the bug template section order
$issue = Join-Path (Get-Location) "u2-l01-issue.md"
$issueOk = $false
if (Test-Path $issue) {
    $i = Get-Content $issue -Raw
    $d = $i.IndexOf("Describe the bug")
    $r = $i.IndexOf("To Reproduce")
    $e = $i.IndexOf("Expected behavior")
    $envIdx = $i.IndexOf("Environment")
    $issueOk = ($d -ge 0) -and ($r -gt $d) -and ($e -gt $r) -and ($envIdx -gt $e)
}
Check "u2-l01-issue.md sections in template order" $issueOk "Describe the bug -> To Reproduce -> Expected behavior -> Environment"

# 4. Issue mentions the recipe repro detail
$reproOk = $false
if (Test-Path $issue) {
    $i = Get-Content $issue -Raw
    $reproOk = ($i -match "--recipe") -and ($i -match "required")
}
Check "issue reproduces the --recipe required-parameter defect" $reproOk "include a minimal recipe snippet"

# 5. Real clone has the templates the learner should have mirrored
$tpl = Join-Path $GooseRepo ".github\ISSUE_TEMPLATE\bug_report.md"
Check "clone has .github/ISSUE_TEMPLATE/bug_report.md" (Test-Path $tpl) "check GOOSE_REPO path"
$cfg = Join-Path $GooseRepo ".github\ISSUE_TEMPLATE\config.yml"
$cfgContent = if (Test-Path $cfg) { Get-Content $cfg -Raw } else { "" }
Check "clone config.yml disables blank issues" ($cfgContent -match "blank_issues_enabled\s*:\s*false") "expected blank_issues_enabled: false"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}