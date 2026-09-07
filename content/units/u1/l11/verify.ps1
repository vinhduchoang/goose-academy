# Goose Contributor Academy - Lab check: u1-l11 Observability incident
# Run from any directory. Validates the incident report + log artifact.
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

# 1. The one-shot grpc warning exists in the exporter
$warn = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\otel\otlp.rs") -Pattern 'OTEL_EXPORTER_OTLP_PROTOCOL=grpc' -ErrorAction SilentlyContinue
Check "otlp.rs warns on OTEL_EXPORTER_OTLP_PROTOCOL=grpc" ($null -ne $warn) "expected one-shot stderr warning"

# 2. Logging + diagnostics foundations exist
$sub = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\logging.rs") -Pattern 'pub fn build_logging_subscriber' -ErrorAction SilentlyContinue
$diag = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\session\diagnostics.rs") -Pattern 'pub fn latest_llm_log_path' -ErrorAction SilentlyContinue
Check "build_logging_subscriber + latest_llm_log_path exist" ($null -ne $sub -and $null -ne $diag) "expected logging + diagnostics helpers"

# 3. Doctor exists as the actuator
$doc = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\doctor.rs") -Pattern 'pub async fn run' -ErrorAction SilentlyContinue
Check "doctor::run exists in doctor.rs" ($null -ne $doc) "expected pub async fn run"

# 4. gen_ai telemetry writer exists
$usage = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\agents\gen_ai_telemetry.rs") -Pattern 'fn record_usage' -ErrorAction SilentlyContinue
Check "gen_ai_telemetry.rs record_usage exists" ($null -ne $usage) "expected fn record_usage"

# 5. Incident log artifact exists with the seeded lines
$logOk = $false
$logPath = Join-Path (Get-Location) "l11-incident.log"
if (Test-Path $logPath) {
    $log = Get-Content $logPath -Raw
    $logOk = ($log -match 'OTEL_EXPORTER_OTLP_PROTOCOL is set to a gRPC') -and ($log -match 'TimeoutError') -and ($log -match 'doctor')
}
Check "l11-incident.log contains the grpc warning + timeout + doctor lines" $logOk "run Step 2 seeding first"

# 6. Root-cause report names the smoking gun + the fix
$reportOk = $false
$repPath = Join-Path (Get-Location) "l11-incident-report.md"
if (Test-Path $repPath) {
    $r = Get-Content $repPath -Raw
    $reportOk = ($r -match 'otlp\.rs') -and ($r -match 'http/protobuf') -and
                ($r -match 'doctor') -and ($r -match 'latest_llm_log_path') -and
                ($r -match 'record_usage')
}
Check "l11-incident-report.md cites otlp.rs http/protobuf doctor diagnostics telemetry" $reportOk "complete Steps 3-5 first"

# 7. PowerShell fix command present in the report
$fixOk = $false
if (Test-Path $repPath) {
    $r = Get-Content $repPath -Raw
    $fixOk = ($r -match 'OTEL_EXPORTER_OTLP_PROTOCOL') -and ($r -match 'env:')
}
Check "report contains the $env:OTEL_EXPORTER_OTLP_PROTOCOL fix command" $fixOk "complete Step 4"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}