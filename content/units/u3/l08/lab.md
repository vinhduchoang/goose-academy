# Lab 3.8 — Build an installable plugin: commands + skills

Timebox: 40-50 min. PowerShell 5.1, your goose checkout (`$env:GOOSE_REPO`).

```powershell
$env:LAB08 = Join-Path (Get-Location) "goose-labs\u3-l08"
$plugin = Join-Path $env:LAB08 "u3-greeter-plugin"
New-Item -ItemType Directory -Force -Path (Join-Path $plugin "commands"), (Join-Path $plugin "skills\greet"), (Join-Path $plugin "hooks") | Out-Null
```

## Step 1 — Read the plugin contract (10 min)

Note in `u3-l08-notes.md`:

- `crates/goose/src/plugins/formats/open_plugins.rs:21` — the four component
  markers; which two does your plugin ship?
- `crates/goose/src/skills/mod.rs:33` — the two required SkillFrontmatter
  fields.
- `crates/goose-cli/src/cli.rs:706` — what the `--auto-update` flag on
  `install` really hints at (auto-update check every 24h).

## Step 2 — Manifest (5 min)

Write `$plugin\plugin.json`:

```json
{
  "name": "u3-greeter-plugin",
  "version": "0.1.0",
  "skills": { "skills": ["skills"] }
}
```

Run the name rule audit (same as l01) and paste its output into notes.

## Step 3 — commands/ slash command (10 min)

Write `$plugin\commands\hello.md`:

```markdown
---
description: Greet the user by name and ask what they are working on
---
Greet the user warmly.

If the user provides a name, address them by it.
Keep the greeting to two sentences and end with one question.
```

Filename minus `.md` = slash command name. A `commands/` entry is a *prompt
template* — write in notes one sentence on how that differs from an MCP tool.

## Step 4 — Two skills (10 min)

`$plugin\skills\greet\SKILL.md`:

```markdown
---
name: greet
description: Friendly greeting conventions used by this team (names, tone, sign-offs)
---
When greeting, prefer first names, lowercase tone, and sign off with
"talk soon" unless the user asks otherwise.
```

Then a second skill of your own choice (`skills/<name>/SKILL.md`) with a
different name. In notes: after install, what is `greet`'s *namespaced* name,
and which line of `open_plugins.rs` performs the rename
(hint: `namespaced_component_name`)? What does the rename protect against?

## Step 5 — hooks stub + local validation walk (10 min)

Write `$plugin\hooks\hooks.json`:

```json
{ "hooks": { "SessionStart": [ { "hooks": [] } ] } }
```

Then simulate the install checks goose runs (no network needed):

```powershell
# 1. name validation
$name = (Get-Content (Join-Path $plugin "plugin.json") -Raw | ConvertFrom-Json).name
if ($name -match '^[a-z0-9][a-z0-9\-\.]*[a-z0-9]$') { "name OK: $name" }

# 2. component markers present
foreach ($marker in @("hooks\hooks.json","commands",".mcp.json")) {
  if (Test-Path (Join-Path $plugin $marker)) { "marker OK: $marker" }
}

# 3. skill frontmatter parses
Get-ChildItem (Join-Path $plugin "skills") -Recurse -Filter SKILL.md | ForEach-Object {
  $head = Get-Content $_.FullName -TotalCount 6
  if (($head -join "`n") -match 'name:' -and ($head -join "`n") -match 'description:') {
    "skill OK: " + $_.Directory.Name
  } else { "skill BROKEN: " + $_.Directory.Name }
}
```

Paste output into notes. Answer: which two checks from
`install_from_manifest` (open_plugins.rs:68) are *not* simulated here, and why
does the real code use a staging dir + atomic rename?

## Verification

```powershell
powershell -File verify.ps1 -LabDir $env:LAB08 -GooseRepo $env:GOOSE_REPO
```

## Homework

- Read `crates/goose/src/slash_commands/slash_command.rs:4-53` — in what order
  do builtins, recipes, and skills merge, and what happens on a name clash?
- Optional (full build): `goose plugin install` with a `file:///`-style URL of
  your repo — record the installed path and the metadata file it wrote.