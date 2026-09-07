# Lab 3.9 — Hooks, permission rules, a bundled subagent

Timebox: 40-50 min. PowerShell 5.1, your goose checkout (`$env:GOOSE_REPO`).
Extend the l08 plugin.

```powershell
$env:LAB09 = Join-Path (Get-Location) "goose-labs\u3-l09"
Copy-Item -Recurse -Force (Join-Path (Get-Location) "goose-labs\u3-l08\u3-greeter-plugin") $env:LAB09
$plugin = Join-Path $env:LAB09 "u3-greeter-plugin"
New-Item -ItemType Directory -Force -Path (Join-Path $plugin "scripts"), (Join-Path $plugin "agents") | Out-Null
```

## Step 1 — Read the hook protocol (10 min)

Read and note in `u3-l09-notes.md`:

- `crates/goose/src/hooks/mod.rs:55` — list all 13 `HookEvent` variants.
- `crates/goose/src/hooks/mod.rs:246` — the two allowed `PreToolUseResult`
  decisions.
- `crates/goose/src/hooks/mod.rs:703` — quote the two stdout JSON shapes for
  blocking hooks, and what empty stdout + exit 0 means.
- `crates/goose/src/hooks/mod.rs:44` — the default hook timeout.

## Step 2 — A blocking hook chain (15 min)

Replace `hooks/hooks.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "developer__shell",
        "hooks": [
          { "type": "command", "command": "${PLUGIN_ROOT}/scripts/guard-shell.bat", "timeout": 10 }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          { "type": "command", "command": "${PLUGIN_ROOT}/scripts/on-start.bat" }
        ]
      }
    ]
  }
}
```

Write `scripts\guard-shell.bat` (PowerShell-friendly batch):

```bat
@echo off
rem PreToolUse blocking hook: deny shell commands when a guard file exists
rem Event JSON arrives on stdin; answer protocol on stdout.
set GUARD=%PLUGIN_ROOT%\guard.txt
if exist "%GUARD%" (
  echo {"decision":"block","reason":"shell guard is active"}
  exit /b 0
)
echo {"decision":"allow"}
exit /b 0
```

And `scripts\on-start.bat`:

```bat
@echo off
rem SessionStart: non-blocking hook; exit 0 is all that is required
echo {"banner":"greeter plugin active"}
exit /b 0
```

In notes: why must a deny decision *still exit 0*? (Read the failure-mode
sentences around `emit_blocking`; note what `on_failure: "block"` changes.)

## Step 3 — Permission rule sketch with remember-scoping (10 min)

Write `u3-l09-permissions.md`: model two rules for the plugin's own files.

```yaml
# rule 1: allow reading notes, scoped by context hash (dir + glob)
tool: developer__text_editor
read:   ["~/.agents/notes/**"]
allow_read_only: true
remember_scope: context_hash

# rule 2: writes need per-call confirmation, never remembered
tool: developer__text_editor
write:  ["~/.agents/notes/**"]
confirm_each: true
```

Answer in the same doc: which struct makes `remember_scope: context_hash`
meaningful (`crates/goose/src/permission/permission_store.rs:12`), which field
would make a rule expire, and which enum carries the permission decision to the
agent (`crates/goose/src/permission/mod.rs:5`).

## Step 4 — A bundled subagent definition (10 min)

Write `agents\note-triage.md` (the Open-Plugins `agents/` marker):

```markdown
---
name: note-triage
description: Triage the user's saved notes, summarize themes,
  and delete obvious duplicates after confirming with the parent context.
---
You are a note librarian.
1. List all notes.
2. Group by topic.
3. Report duplicates; never delete without a confirmation tool call.
Answer in three bullet groups only.
```

In `u3-l09-notes.md` answer: which fields of `SubagentRunParams`
(`crates/goose/src/agents/subagent_handler.rs:36`) would carry this definition
as a `TaskConfig`, which field bounds `max_turns`, and what the parent agent
receives from `run_subagent_task` (line 47).

## Verification

```powershell
powershell -File verify.ps1 -LabDir $env:LAB09 -GooseRepo $env:GOOSE_REPO
```

## Homework

- `crates/goose/src/permission/permission_judge.rs:41` — what tool name does
  the judge register, and what does it classify first?
- Grep the hooks module for `on_failure` — list every accepted mode and its
  default when omitted.