<# Goose Contributor Academy - Lab check: u3-l09 Hooks, permissions, subagents
   Checks the plugin's hooks/hooks.json (blocking PreToolUse + non-blocking
   SessionStart), the guard/on-start scripts with the stdout decision
   protocol, the permission rule sketch, the agents/ definition, notes, and
   goose-repo grep evidence.
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

# The plugin may live directly in LabDir or in LabDir\u3-greeter-plugin
$pluginDir = $LabDir
if ((-not (Test-Path (Join-Path $pluginDir "hooks"))) -and (Test-Path (Join-Path $LabDir "u3-greeter-plugin"))) {
    $pluginDir = Join-Path $LabDir "u3-greeter-plugin"
}

# 1. hooks.json declares PreToolUse with a matcher + command action
$hooksPath = Join-Path $pluginDir "hooks\hooks.json"
$hooks = if (Test-Path $hooksPath) { Get-Content $hooksPath -Raw } else { "" }
Check "hooks.json has PreToolUse matcher + command action" `
    ($hooks -match 'PreToolUse' -and $hooks -match 'matcher' -and $hooks -match '"type": "command"' -or $hooks -match '"type":\s*"command"') `
    "rewrite hooks.json per Step 2"

# 2. ${PLUGIN_ROOT} token used for command paths
Check "hook commands use ${PLUGIN_ROOT} token" ($hooks -match 'PLUGIN_ROOT') "use the PLUGIN_ROOT substitution"

# 3. Guard script speaks the stdout decision protocol
$guardPath = Join-Path $pluginDir "scripts\guard-shell.bat"
$guard = if (Test-Path $guardPath) { Get-Content $guardPath -Raw } else { "" }
Check "guard-shell.bat emits decision block/allow JSON + exit 0" `
    ($guard -match 'decision' -and $guard -match 'block' -and $guard -match 'allow' -and $guard -match 'exit /b 0') `
    "write the PreToolUse guard per Step 2"

# 4. SessionStart hook + on-start script (non-blocking, exit 0)
$startPath = Join-Path $pluginDir "scripts\on-start.bat"
$start = if (Test-Path $startPath) { Get-Content $startPath -Raw } else { "" }
Check "on-start.bat handles SessionStart with exit 0" `
    (($hooks -match 'SessionStart') -and ($start -match 'exit /b 0')) `
    "add the SessionStart hook + script"

# 5. Permission rule sketch with remember-scope + expiry question
$permPath = Join-Path $LabDir "u3-l09-permissions.md"
$perm = if (Test-Path $permPath) { Get-Content $permPath -Raw } else { "" }
Check "u3-l09-permissions.md models scoped remember + per-call confirm" `
    ($perm -match 'context_hash' -and $perm -match 'expiry' -and $perm -match 'confirm_each') `
    "create the permission rules doc from Step 3"

# 6. Bundled subagent definition under agents/
$agentsDir = Join-Path $pluginDir "agents"
$agentFiles = @()
if (Test-Path $agentsDir) { $agentFiles = Get-ChildItem $agentsDir -Filter *.md -ErrorAction SilentlyContinue }
Check "agents/ ships an agent definition" ($agentFiles.Count -ge 1) "add agents/note-triage.md per Step 4"

# 7. Notes record the hook protocol + SubagentRunParams findings
$notesPath = Join-Path $LabDir "u3-l09-notes.md"
$notes = if (Test-Path $notesPath) { Get-Content $notesPath -Raw } else { "" }
Check "u3-l09-notes.md records decision protocol + SubagentRunParams" `
    ($notes -match 'decision' -and $notes -match 'SubagentRunParams' -and $notes -match 'emit_blocking') `
    "create u3-l09-notes.md per Steps 1-4"

# 8. Goose-repo evidence: HookEvent + permission store + subagent handler
$hits = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\hooks\mod.rs") -Pattern 'pub enum HookEvent' -ErrorAction SilentlyContinue
$hits2 = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\permission\permission_store.rs") -Pattern 'context_hash' -ErrorAction SilentlyContinue
$hits3 = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\agents\subagent_handler.rs") -Pattern 'run_subagent_task' -ErrorAction SilentlyContinue
Check "goose repo: HookEvent + context_hash + run_subagent_task found" (($null -ne $hits) -and ($null -ne $hits2) -and ($null -ne $hits3)) "grep hooks/mod.rs, permission_store.rs, subagent_handler.rs"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}