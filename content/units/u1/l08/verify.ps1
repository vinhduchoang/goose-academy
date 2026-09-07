# Goose Contributor Academy - Lab check: u1-l08 Extension system lifecycle
# Run from any directory. Validates the extension trace artifact.
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

# 1. Discovery entry exists
$resolve = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\config\extensions.rs") -Pattern 'resolve_extensions_for_new_session' -ErrorAction SilentlyContinue
Check "resolve_extensions_for_new_session exists in config/extensions.rs" ($null -ne $resolve) "expected discovery entry"

# 2. ExtensionConfig is the serde-tagged contract
$cfg = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\agents\extension.rs") -Pattern '^pub enum ExtensionConfig' -ErrorAction SilentlyContinue
Check "ExtensionConfig enum exists in agents/extension.rs" ($null -ne $cfg) "expected pub enum ExtensionConfig"

# 3. Malware gate exists
$mw = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\agents\extension_malware_check.rs") -Pattern 'pub async fn deny_if_malicious' -ErrorAction SilentlyContinue
Check "deny_if_malicious exists in extension_malware_check.rs" ($null -ne $mw) "expected spawn-time malware gate"

# 4. The live registry exists
$em = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\agents\extension_manager.rs") -Pattern '^pub struct ExtensionManager' -ErrorAction SilentlyContinue
Check "ExtensionManager struct exists in extension_manager.rs" ($null -ne $em) "expected pub struct ExtensionManager"

# 5. Load boundary exists on Agent
$add = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\agents\agent.rs") -Pattern 'pub async fn add_extension' -ErrorAction SilentlyContinue
Check "Agent::add_extension exists in agent.rs" ($null -ne $add) "expected pub async fn add_extension"

# 6. Builtin servers are registered in goose-mcp
$builtin = Select-String -Path (Join-Path $GooseRepo "crates\goose-mcp\src\lib.rs") -Pattern 'BUILTIN_EXTENSIONS' -ErrorAction SilentlyContinue
Check "BUILTIN_EXTENSIONS static exists in goose-mcp/src/lib.rs" ($null -ne $builtin) "expected Lazy<HashMap> registration"

# 7. Notes artifact: full chain + variant fields + malware question
$notesOk = $false
$notesPath = Join-Path (Get-Location) "l08-extension-trace.md"
if (Test-Path $notesPath) {
    $notes = Get-Content $notesPath -Raw
    $notesOk = ($notes -match 'add_extension') -and ($notes -match 'extension_manager') -and
               ($notes -match 'deny_if_malicious') -and ($notes -match 'rmcp')
}
Check "l08-extension-trace.md covers resolve, add_extension, manager spawn, malware, rmcp" $notesOk "complete Steps 1-6 first"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}