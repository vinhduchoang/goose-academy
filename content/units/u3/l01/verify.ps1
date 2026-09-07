<# Goose Contributor Academy - Lab check: u3-l01 Extension anatomy
   Validates the learner's hand-written manifest artifacts (plugin.json,
   .mcp.json, ext config yaml), their notes, and their goose-repo grep
   evidence for the validation pipeline and malware check.
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

# 1. plugin.json manifest exists and carries a valid name
$manifestPath = Join-Path $LabDir "plugin.json"
$manifestOk = $false
if (Test-Path $manifestPath) {
    try {
        $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
        $manifestOk = ($manifest.name -match '^[a-z0-9][a-z0-9\-\.]*[a-z0-9]$') -and `
                      ($manifest.name.Length -ge 1) -and ($manifest.name.Length -le 64) -and `
                      ($manifest.name -notmatch '\-\-|\.\.')
    } catch { $manifestOk = $false }
}
Check "plugin.json exists with a validate_plugin_name-compliant name" $manifestOk "manifest missing or invalid name at $manifestPath"

# 2. .mcp.json exists and parses with an mcpServers map
$mcpPath = Join-Path $LabDir ".mcp.json"
$mcpOk = $false
if (Test-Path $mcpPath) {
    try {
        $mcp = Get-Content $mcpPath -Raw | ConvertFrom-Json
        $mcpOk = $null -ne $mcp.mcpServers
    } catch { $mcpOk = $false }
}
Check ".mcp.json exists with mcpServers" $mcpOk "missing or malformed .mcp.json at $mcpPath"

# 3. The config.yaml-style extension entry uses stdio + cmd
$extYaml = Join-Path $LabDir "u3-l01-ext.yaml"
$extContents = if (Test-Path $extYaml) { Get-Content $extYaml -Raw } else { "" }
Check "u3-l01-ext.yaml declares an enabled stdio extension with cmd" `
    ($extContents -match 'type:\s*stdio' -and $extContents -match 'cmd:' -and $extContents -match 'enabled:\s*true') `
    "write the extensions entry from Step 3"

# 4. Broken-entries repro artifact from Step 4
$brokenOk = Test-Path (Join-Path $LabDir "broken-entries.json")
Check "broken-entries.json repro created" $brokenOk "create the streamable_http url-vs-uri repro from Step 4"

# 5. Notes file records the validation findings
$notesPath = Join-Path $LabDir "u3-l01-notes.md"
$notes = if (Test-Path $notesPath) { Get-Content $notesPath -Raw } else { "" }
Check "u3-l01-notes.md records uri-vs-url error + four ExtensionConfig variants" `
    ($notes -match 'uri' -and $notes -match 'stdio' -and $notes -match 'streamable_http') `
    "create u3-l01-notes.md with the Step 1 and Step 4 findings"

# 6. Goose-repo evidence: ExtensionConfig enum
$m = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\agents\extension.rs") -Pattern 'pub enum ExtensionConfig' -ErrorAction SilentlyContinue
Check "goose repo: ExtensionConfig enum found in agents/extension.rs" ($null -ne $m) "verify your goose clone has crates/goose/src/agents/extension.rs"

# 7. Goose-repo evidence: malware check queries OSV for MAL- advisories
$n = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\agents\extension_malware_check.rs") -Pattern 'MAL-' -ErrorAction SilentlyContinue
Check "goose repo: malware check filters MAL- advisories (extension_malware_check.rs)" ($null -ne $n) "grep crates/goose/src/agents/extension_malware_check.rs for MAL-"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}