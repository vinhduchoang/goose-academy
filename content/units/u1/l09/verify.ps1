# Goose Contributor Academy - Lab check: u1-l09 MCP internals
# Run from any directory. Validates MCP client/server + schema-normalization work.
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

# 1. rmcp is the workspace protocol implementation
$rootToml = Get-Content (Join-Path $GooseRepo "Cargo.toml") -Raw -ErrorAction SilentlyContinue
Check 'root Cargo.toml pins rmcp 3.0.0 in [workspace.dependencies]' ($rootToml -match 'rmcp = \{ version = "3.0.0"') "expected rmcp workspace dep"

# 2. MCP client wrapper exists
$client = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\agents\mcp_client.rs") -Pattern '^pub struct McpClient' -ErrorAction SilentlyContinue
Check "McpClient struct exists in agents/mcp_client.rs" ($null -ne $client) "expected pub struct McpClient"

# 3. Protocol version pinned
$pv = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\agents\agent.rs") -Pattern 'V_2025_11_25' -ErrorAction SilentlyContinue
Check "MCP_PROTOCOL_VERSION pinned to V_2025_11_25 in agent.rs" ($null -ne $pv) "expected const MCP_PROTOCOL_VERSION"

# 4. Server runner + builtins exist in goose-mcp
$serve = Select-String -Path (Join-Path $GooseRepo "crates\goose-mcp\src\mcp_server_runner.rs") -Pattern 'pub async fn serve' -ErrorAction SilentlyContinue
$builtin = Select-String -Path (Join-Path $GooseRepo "crates\goose-mcp\src\lib.rs") -Pattern 'BUILTIN_EXTENSIONS' -ErrorAction SilentlyContinue
Check "goose-mcp serve() + BUILTIN_EXTENSIONS exist" ($null -ne $serve -and $null -ne $builtin) "expected stdio serve loop + static map"

# 5. Normalization layer exists with the repair fns
$ns = Get-Content (Join-Path $GooseRepo "crates\goose\src\agents\tool_schema_normalize.rs") -Raw -ErrorAction SilentlyContinue
$norms = ($ns -match 'collapse_const_unions') -and ($ns -match 'inline_refs') -and ($ns -match 'percent_decode')
Check "tool_schema_normalize.rs has collapse_const_unions/inline_refs/percent_decode" $norms "expected normalization repairs"

# 6. Collision-drill answers exist
$collisionOk = $false
$cPath = Join-Path (Get-Location) "l09-collision.md"
$notesPath = Join-Path (Get-Location) "l09-mcp-notes.md"
if (Test-Path $cPath) {
    $c = Get-Content $cPath -Raw
    $collisionOk = ($c -match 'get_prefixed_tools') -and ($c -match '\$ref') -and ($c -match 'normalize_input_schema')
}
Check "l09-collision.md answers prefixing + dangling $ref + normalization order" $collisionOk "complete Step 4"
$n2 = $false
if (Test-Path $notesPath) {
    $n = Get-Content $notesPath -Raw
    $n2 = ($n -match 'McpClientTrait') -and ($n -match 'MCP_PROTOCOL_VERSION')
}
Check "l09-mcp-notes.md covers the trait seam + protocol pin" $n2 "complete Steps 1-3 first"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}