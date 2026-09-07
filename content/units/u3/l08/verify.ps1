<# Goose Contributor Academy - Lab check: u3-l08 Plugins & skills
   Checks the learner's plugin repo: plugin.json (valid name), commands/
   prompt files, skills with SKILL.md frontmatter, hooks stub, validation
   notes, and goose-repo grep evidence.
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
if (-not (Test-Path (Join-Path $pluginDir "plugin.json")) -and
    (Test-Path (Join-Path $LabDir "u3-greeter-plugin"))) {
    $pluginDir = Join-Path $LabDir "u3-greeter-plugin"
}

# 1. plugin.json with a validate_plugin_name-compliant name
$manifestPath = Join-Path $pluginDir "plugin.json"
$manifestOk = $false
if (Test-Path $manifestPath) {
    try {
        $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
        $manifestOk = ($manifest.name -match '^[a-z0-9][a-z0-9\-\.]*[a-z0-9]$') -and `
                      ($manifest.name.Length -le 64) -and ($manifest.name -notmatch '\-\-|\.\.')
    } catch { $manifestOk = $false }
}
Check "plugin.json exists with valid name" $manifestOk "create plugin.json (name rules at open_plugins.rs:206)"

# 2. commands/ contains at least one markdown prompt (slash command)
$commandsDir = Join-Path $pluginDir "commands"
$commandFiles = @()
if (Test-Path $commandsDir) { $commandFiles = Get-ChildItem $commandsDir -Filter *.md -ErrorAction SilentlyContinue }
Check "commands/ ships >=1 .md slash command" ($commandFiles.Count -ge 1) "add commands/<name>.md per Step 3"

# 3. command prompt carries a description frontmatter
$cmdOk = $false
foreach ($c in $commandFiles) {
    $head = Get-Content $c.FullName -TotalCount 6 -ErrorAction SilentlyContinue
    if (($head -join "`n") -match 'description:') { $cmdOk = $true }
}
Check "slash command file has description frontmatter" $cmdOk "frontmatter drives the command listing"

# 4. skills/ ships >=2 SKILL.md folders with name+description
$skillsDir = Join-Path $pluginDir "skills"
$skillFiles = @()
if (Test-Path $skillsDir) { $skillFiles = Get-ChildItem $skillsDir -Recurse -Filter SKILL.md -ErrorAction SilentlyContinue }
$skillOk = $false
$validSkills = 0
foreach ($s in $skillFiles) {
    $head = Get-Content $s.FullName -TotalCount 8 -ErrorAction SilentlyContinue
    if (($head -join "`n") -match 'name:' -and ($head -join "`n") -match 'description:') { $validSkills++ }
}
$skillOk = ($skillFiles.Count -ge 2) -and ($validSkills -ge 2)
Check "skills/ ships >=2 valid SKILL.md skills" $skillOk "create the greet skill + one more per Step 4"

# 5. hooks/hooks.json stub exists (component marker)
$hooksOk = Test-Path (Join-Path $pluginDir "hooks\hooks.json")
Check "hooks/hooks.json marker present" $hooksOk "create the SessionStart stub from Step 5"

# 6. Notes record install pipeline + namespacing findings
$notesPath = Join-Path $LabDir "u3-l08-notes.md"
$notes = if (Test-Path $notesPath) { Get-Content $notesPath -Raw } else { "" }
Check "u3-l08-notes.md records COMPONENT_MARKERS + namespaced_component_name" `
    ($notes -match 'COMPONENT_MARKERS' -and $notes -match 'namespaced') `
    "create u3-l08-notes.md per Steps 1, 4, 5"

# 7. Goose-repo evidence: plugin CLI + skill discovery exist
$hits = Select-String -Path (Join-Path $GooseRepo "crates\goose-cli\src\cli.rs") -Pattern 'enum PluginCommand' -ErrorAction SilentlyContinue
$hits2 = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\skills\mod.rs") -Pattern 'SkillFrontmatter' -ErrorAction SilentlyContinue
Check "goose repo: PluginCommand enum + SkillFrontmatter found" (($null -ne $hits) -and ($null -ne $hits2)) "grep cli.rs + skills/mod.rs"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}