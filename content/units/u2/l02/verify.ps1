# Goose Contributor Academy - Lab check: u2-l02 Bug reproduction & bisecting
<# Verifies the scratch bisect repo, the bisect log, and the real-history
   notes. Cheap file checks only - no cargo builds. #>
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

$scratch = Join-Path (Get-Location) "u2-l02-scratch"

# 1. Scratch repo exists with at least 6 commits
$commitsOk = $false
if (Test-Path $scratch) {
    Push-Location $scratch
    try {
        $n = @(git rev-list --count HEAD 2>$null)
        $commitsOk = ($n.Count -gt 0) -and ([int]$n[0] -ge 6)
    } catch { $commitsOk = $false } finally { Pop-Location }
}
Check "u2-l02-scratch repo has >= 6 commits" $commitsOk "git init + at least 6 commits required"

# 2. Repro script exists and encodes the fencepost assertion
$check = Join-Path $scratch "check.ps1"
$reproOk = $false
if (Test-Path $check) {
    $c = Get-Content $check -Raw
    $reproOk = ($c -match "1000") -and ($c -match "exit 1")
}
Check "check.ps1 is a runnable repro (exit 0/1)" $reproOk "must assert Get-Label 1000 and exit non-zero on failure"

# 3. Bisect log exists and names a first bad commit
$logFile = Join-Path (Get-Location) "bisect-log.md"
$bisectOk = $false
if (Test-Path $logFile) {
    $l = Get-Content $logFile -Raw
    $bisectOk = ($l -match "first bad commit") -and ($l -match "#.*(good|bad|starts)")
}
Check "bisect-log.md records first bad commit" $bisectOk 'capture via: git bisect log >'

# 4. The bisected SHA is a real commit of the scratch repo
$shaOk = $false
if (Test-Path $logFile) {
    $m = [regex]::Match((Get-Content $logFile -Raw), "first bad commit: \[([0-9a-f]+)\]")
    if (-not $m.Success) { $m = [regex]::Match((Get-Content $logFile -Raw), "first bad commit[^\[]*\[?([0-9a-f]{7,40})") }
    if ($m.Success) {
        Push-Location $scratch
        try { $shaOk = (git rev-list HEAD | Select-String $m.Groups[1].Value) -ne $null } catch {} finally { Pop-Location }
    }
}
Check "bisected SHA belongs to the scratch history" $shaOk "re-run bisect if SHA does not resolve"

# 5. Real-history notes reference the token_counter fix commits
$real = Join-Path (Get-Location) "real-gitlog.md"
$realOk = $false
if (Test-Path $real) {
    $r = Get-Content $real -Raw
    $realOk = ($r -match "509fcac69") -and ($r -match "08e748051")
}
Check "real-gitlog.md cites 509fcac69 and 08e748051" $realOk "run git log in the clone and record both hashes"

# 6. Clone still has the files cited in the lesson
$tc = Join-Path $GooseRepo "crates\goose\src\token_counter.rs"
$lrh = Join-Path $GooseRepo "crates\goose\src\agents\large_response_handler.rs"
Check "clone has token_counter.rs + large_response_handler.rs" ((Test-Path $tc) -and (Test-Path $lrh)) "check GOOSE_REPO path"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}