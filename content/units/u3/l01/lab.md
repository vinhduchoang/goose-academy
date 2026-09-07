# Lab 3.1 — Hand-write a manifest; pass every validation stage

Timebox: 40-50 min. Do everything in PowerShell 5.1 against your local
`goose` checkout (`$env:GOOSE_REPO`, defaults to `C:\Users\admin\projects\goose`).

Create a lab workspace folder first (you'll reuse it all unit):

```powershell
$labRoot = Join-Path (Get-Location) "goose-labs"
New-Item -ItemType Directory -Force -Path (Join-Path $labRoot "u3-l01") | Out-Null
$env:LAB01 = Join-Path $labRoot "u3-l01"
```

## Step 1 — Read the two surfaces (10 min)

Open (or `Get-Content`) these and answer in `u3-l01-notes.md` in `$env:LAB01`:

1. `crates/goose/src/agents/extension.rs` — list the four `ExtensionConfig`
   variants and one field each (see line 161).
2. `crates/goose/src/plugins/formats/open_plugins.rs` — what are the three
   manifest paths goose probes, and the four fields of `OpenPluginsManifest`?

## Step 2 — Write a valid plugin manifest (10 min)

In `$env:LAB01`, create `plugin.json`:

```json
{
  "name": "u3-team-notes",
  "version": "0.1.0",
  "skills": { "skills": ["skills"] },
  "mcpServers": { "mcpServers": {} }
}
```

Check your name against the rules at
`crates/goose/src/plugins/formats/open_plugins.rs:206`. Run a rule audit:

```powershell
$name = "u3-team-notes"
if ($name.Length -lt 1 -or $name.Length -gt 64) { "FAIL length" }
elseif ($name -notmatch '^[a-z0-9][a-z0-9\-\.]*[a-z0-9]$') { "FAIL charset" }
elseif ($name -match '\-\-|\.\.') { "FAIL consecutive" }
else { "PASS: $name obeys validate_plugin_name" }
```

Then create `.mcp.json` next to it:

```json
{
  "mcpServers": {
    "notes": { "command": "node", "args": ["server.js"] }
  }
}
```

## Step 3 — Config.yaml extension entry (10 min)

In `$env:LAB01`, write `u3-l01-ext.yaml` — an `extensions` map with ONE entry:

```yaml
extensions:
  notes:
    enabled: true
    type: stdio
    cmd: node
    args: [server.js]
    timeout: 300
```

Compare it field-by-field with the `Stdio` variant at
`crates/goose/src/agents/extension.rs:164`.

## Step 4 — Reproduce a real validation error (10 min)

`crates/goose/src/agents/validate_extensions.rs:43` contains this exact message:

```
has "url" field but streamable_http expects "uri" — did you mean "uri"?
```

Write a deliberately broken bundled-entries JSON in `$env:LAB01`:

```powershell
$broken = '[{ "id": "badhttp", "name": "Bad HTTP",
  "type": "streamable_http", "url": "http://localhost:3000/mcp" }]'
Set-Content -Path (Join-Path $env:LAB01 "broken-entries.json") -Value $broken
```

Then trace the code path that would reject it: `validate_bundled_extensions` is
called from `crates/goose-cli/src/cli.rs:2941` (`use goose::agents::validate_extensions::validate_bundled_extensions`).
In your notes, write the 3 checks this validator performs *before* serde
deserialization and quote the `uri` error message.

## Step 5 — Trace the malware check (10 min)

Find where the check fires at runtime:

```powershell
Select-String -Path (Join-Path $env:GOOSE_REPO "crates\goose\src\agents\extension_manager.rs") `
  -Pattern "deny_if_malicious_cmd_args"
```

Then read `crates/goose/src/agents/extension_malware_check.rs:44` and answer in
notes: which two executables trigger an OSV lookup, what `MAL-` means, and what
"fail open" means when the OSV request errors. Verify the endpoint const at line 365.

## Verification

```powershell
powershell -File verify.ps1 -LabDir $env:LAB01 -GooseRepo $env:GOOSE_REPO
```

Mark this lab verified in the app when it prints `VERIFY PASSED`.

## Homework

- Open `crates/goose/src/plugins/formats/gemini.rs:14` — what does the Gemini
  manifest require that Open Plugins makes optional? One sentence in your notes.
- Skim `documentation/docs/getting-started/using-extensions.md:15` — write one
  sentence on how the malware check is described to end users.