# Goose Contributor Academy - Lab check: u2-l04 Testing doctrine
<# Verifies the scratch mock provider crate layout, the notes about the
   record-replay seam, and greps in the real clone. #>
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

$scratch = Join-Path (Get-Location) "u2-l04-scratch"
$notes = Join-Path (Get-Location) "u2-l04-notes.md"

# 1. Scratch lib defines the provider seam with a mock implementing the trait
$libOk = $false
if (Test-Path (Join-Path $scratch "src\lib.rs")) {
    $l = Get-Content (Join-Path $scratch "src\lib.rs") -Raw
    $libOk = ($l -match "impl ChatProvider for MockProvider") -and ($l -match "fn name\(&self\)") -and ($l -match "fn complete")
}
Check "src/lib.rs: MockProvider implements ChatProvider" $libOk "trait + mock + name()/complete() required"

# 2. Integration test in tests/ folder (preferred layer)
$itOk = $false
if (Test-Path (Join-Path $scratch "tests\mock_provider_test.rs")) {
    $i = Get-Content (Join-Path $scratch "tests\mock_provider_test.rs") -Raw
    $itOk = ($i -match "#\[test\]") -and ($i -match "MockProvider")
}
Check "tests/mock_provider_test.rs exercises the mock" $itOk "integration test in tests/, not in src"

# 3. Unit test module for the pure helper inside the lib
Check "lib.rs has #[cfg(test)] unit test for usage_chars" ($libOk -and ((Get-Content (Join-Path $scratch "src\lib.rs") -Raw) -match "usage_chars")) "add the chars() helper + unit test"

# 4. Notes exist and cover the record-replay seam
$notesOk = (Test-Path $notes)
Check "u2-l04-notes.md exists" $notesOk "run all steps and record answers"
$notesRaw = if ($notesOk) { Get-Content $notes -Raw } else { "" }
Check "notes explain what record + replay modes do" ($notesRaw -match "GOOSE_RECORD_MCP|record") "describe mode branch + replay dir"
Check "notes cover what just record-mcp-tests does" ($notesRaw -match "record-mcp-tests") "three ordered actions from Justfile:456"

# 5. Clone greps: Justfile seam, replay dir, fixture server
$jf = Join-Path $GooseRepo "Justfile"
$jfOk = $false
if (Test-Path $jf) {
    $j = Get-Content $jf -Raw
    $jfOk = ($j -match "record-mcp-tests") -and ($j -match "mcp_replays")
}
Check "clone Justfile defines record-mcp-tests + replays dir" $jfOk "verify GOOSE_REPO path"

$replays = Join-Path $GooseRepo "crates\goose\tests\mcp_replays"
$replaysOk = $false
if (Test-Path $replays) { $replaysOk = @(Get-ChildItem $replays -File).Count -gt 0 }
Check "clone has recorded mcp_replays artifacts" $replaysOk "non-empty replay directory expected"

$fixture = Join-Path $GooseRepo "crates\goose-test-support\src\mcp.rs"
Check "clone goose-test-support has McpFixtureServer" (Test-Path $fixture) "see crates/goose-test-support/src/mcp.rs"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}