<# Goose Contributor Academy - Lab check: u3-l06 MCP server basics
   Checks the notes-server crate (rmcp dep, #[tool], #[tool_router],
   CallToolResult/ErrorData, INVALID_PARAMS guard, stdio serving), the
   extension config entry, notes, and goose-repo grep evidence.
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

# The server crate may live directly in LabDir or in LabDir\notes-server
$crateDir = $LabDir
if (-not (Test-Path (Join-Path $crateDir "Cargo.toml"))) {
    $crateDir = Join-Path $LabDir "notes-server"
}

$cargoPath = Join-Path $crateDir "Cargo.toml"
$mainPath = Join-Path $crateDir "src\main.rs"
$cargo = if (Test-Path $cargoPath) { Get-Content $cargoPath -Raw } else { "" }
$main = if (Test-Path $mainPath) { Get-Content $mainPath -Raw } else { "" }

# 1. Crate depends on rmcp with server + macros features
Check "notes-server Cargo.toml uses rmcp (server + macros)" `
    ($cargo -match '\[package\]' -and $cargo -match 'rmcp' -and $cargo -match 'macros') `
    "scaffold notes-server per Step 2"

# 2. Server struct with ToolRouter + instructions
Check "server struct holds ToolRouter<Self> + instructions" `
    ($main -match 'ToolRouter<Self>' -and $main -match 'instructions') `
    "mirror MemoryServer at crates/goose-mcp/src/memory/mod.rs:104"

# 3. #[tool_router] macro on the impl
Check "#[tool_router(router = tool_router)] applied" `
    ($main -match '#\[tool_router') `
    "use the router macro as in memory/mod.rs:116"

# 4. A #[tool] with typed JsonSchema params + CallToolResult
Check "#[tool] fns with typed Parameters + CallToolResult" `
    ($main -match '#\[tool\(' -and $main -match 'CallToolResult' -and $main -match 'JsonSchema') `
    "declare tools per memory/mod.rs:390"

# 5. Input validation via ErrorData (no panics)
Check "empty-input guard returns ErrorData::new" `
    ($main -match 'ErrorData::new' -and $main -match 'INVALID_PARAMS') `
    "validate params per memory/mod.rs:402"

# 6. stdio serving wired in main()
Check "main() serves over rmcp stdio" `
    ($main -match 'stdio|serve_directly') `
    "serve via rmcp::transport::stdio() per examples/mcp.rs:31"

# 7. Extension config entry for goose
$extPath = Join-Path $LabDir "u3-l06-ext.yaml"
$ext = if (Test-Path $extPath) { Get-Content $extPath -Raw } else { "" }
Check "u3-l06-ext.yaml declares the stdio extension entry" `
    ($ext -match 'type:\s*stdio' -and $ext -match 'cmd:' -and $ext -match 'timeout:') `
    "create the extensions entry from Step 4"

# 8. Notes capture server anatomy + goose client wiring
$notesPath = Join-Path $LabDir "u3-l06-notes.md"
$notes = if (Test-Path $notesPath) { Get-Content $notesPath -Raw } else { "" }
Check "u3-l06-notes.md records memory server anatomy + McpClient wiring" `
    ($notes -match 'RequestContext' -and $notes -match 'McpClient') `
    "create u3-l06-notes.md per Steps 1 and 4"

# 9. Goose-repo evidence: upstream reference exists
$m = Select-String -Path (Join-Path $GooseRepo "crates\goose-mcp\src\memory\mod.rs") -Pattern 'tool_router' -ErrorAction SilentlyContinue
Check "goose repo: memory/mod.rs tool_router reference found" ($null -ne $m) "grep crates/goose-mcp/src/memory/mod.rs"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}