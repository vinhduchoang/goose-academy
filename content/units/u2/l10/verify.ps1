# Goose Contributor Academy - Lab check: u2-l10 Review mastery
<# Verifies the findings from the two planted diffs, the verdict section,
   and greps the clone's review policy sources. #>
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

$reviewDir = Join-Path (Get-Location) "u2-l10-review"
$findings = Join-Path (Get-Location) "u2-l10-findings.md"
$notes = Join-Path (Get-Location) "u2-l10-notes.md"

# 1. Both planted diffs exist in the review directory
Check "u2-l10-review/diff1.diff exists" (Test-Path (Join-Path $reviewDir "diff1.diff")) "copy the planted agent.rs diff"
Check "u2-l10-review/diff2.diff exists" (Test-Path (Join-Path $reviewDir "diff2.diff")) "copy the planted Cargo.toml/base.rs diff"

# 2. Findings file with the required violation coverage
$fOk = (Test-Path $findings)
Check "u2-l10-findings.md exists" $fOk "one numbered finding per violation"
$f = if ($fOk) { Get-Content $findings -Raw } else { "" }

Check "findings catch the string_slice panic" ($f -match "string_slice|byte slice|panic") "the 80-char slice on multibyte text"
Check "findings catch missing parity" ($f -match "parity") "no state_machine/ops path change"
Check "findings catch hand-edited Cargo.toml" ($f -match "cargo add") "dependency added without cargo add"
Check "findings catch unwrap on fallible path" ($f -match "unwrap") "anyhow doctrine violated"
Check "findings catch restating comment" ($f -match "comment") "the Initialize-style comment"

# 3. Verdict section picks a blocker
Check "findings have a Verdict section" ($f -match "Verdict") "block the PR with one comment + requested changes"

# 4. Notes list the Rules/Never sections and the deny policy location
$nOk = (Test-Path $notes)
Check "u2-l10-notes.md exists" $nOk "record both AGENTS.md sections + deny.toml levels"
$n = if ($nOk) { Get-Content $notes -Raw } else { "" }
Check "notes mention deny.toml at repo root" ($n -match "deny\.toml") "note the relocation from plan-era rust-toolchain path"
Check "notes mention the advisory levels" ($n -match "yanked") "yanked deny, unmaintained/unsound none"

# 5. Clone greps of the policy sources
$dn = Join-Path $GooseRepo "deny.toml"
$dnOk = $false
if (Test-Path $dn) { $dnOk = (Get-Content $dn -Raw) -match "yanked = `"deny`"" }
Check "clone root deny.toml denies yanked crates" $dnOk "verify GOOSE_REPO path"

$ag = Join-Path $GooseRepo "AGENTS.md"
$agOk = $false
if (Test-Path $ag) {
    $a = Get-Content $ag -Raw
    $agOk = ($a -match "## Never") -and ($a -match "Merge without running clippy")
}
Check "clone AGENTS.md Never section + clippy rule" $agOk "expected review blockers"

$wf = Join-Path $GooseRepo ".github\workflows\cargo-deny.yml"
Check "clone has cargo-deny workflow" (Test-Path $wf) "expected Cargo Deny CI"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}