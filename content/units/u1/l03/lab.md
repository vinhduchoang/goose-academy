# Lab 1.3 — Change one config key and follow it into runtime

Timebox: 40-50 min. PowerShell 5.1, goose checkout at `$env:GOOSE_REPO`.

Goal: pick a config key, change it in the *right layer*, and prove with code
evidence where the runtime reads it — including the legacy/state-machine parity
difference.

## Step 1 — Locate your config layers (5 min)

Find the system + user config paths on your machine. Windows system path is
`C:\ProgramData\goose\config.yaml` (`crates/goose/src/config/base.rs:157-171`).
Your user config lives under your home `.config\goose\` folder. Create a
workspace copy if it doesn't exist:

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.config\goose" | Out-Null
Copy-Item "$env:USERPROFILE\.config\goose\config.yaml" "$env:USERPROFILE\.config\goose\config.yaml.bak" -ErrorAction SilentlyContinue
```

## Step 2 — Change GOOSE_MAX_TURNS (5 min)

Add or edit a key with a distinctive value:

```yaml
GOOSE_MAX_TURNS: 4
```

(Try first in the file the `config_paths` comment says receives writes — the
last file in the list. If you are unsure which one, add it to the user file.)

## Step 3 — Trace the key into the code (20 min)

Write the trace into `l03-config-trace.md` with file:line evidence at every hop:

1. `crates/goose/src/agents/agent.rs:2515` — copy the exact expression that
   reads the key in the legacy loop. What is `DEFAULT_MAX_TURNS` (find the
   const)? What value wins if the key is absent?
2. `crates/goose/src/agents/agent.rs:1630` — the state machine path. Is the
   fallback chain identical? If the value were `"four"` (a string), what
   happens in each path — and where does the error land?
3. Find the *writer* side: grep for `set_param` / `set_goose_` accessors in
   `crates/goose/src/config/base.rs` and list 3 typed writers (e.g. the
   thinking-effort one). What does `set_goose_thinking_effort` at
   `base.rs:1362` do differently from a free `set_param("KEY", v)` call?
4. Find one migration: read `crates/goose/src/config/migrations.rs`, and copy
   the signature/lines of one migration that rewrites an old key. What old key
   does it protect?

## Step 4 — Observe the layer precedence (10 min)

Test precedence without a full agent run. Create a scratch config fixture and
use the repo's own test to confirm your reading:

```powershell
Set-Location $env:GOOSE_REPO
Select-String -Path "crates\goose\src\config\base.rs" -Pattern "merge_config_values" |
  Select-Object -First 3 LineNumber, Line
```

Read the function you found. In `l03-config-trace.md`, write the precedence
rule in one sentence, then state which file's `GOOSE_MAX_TURNS` survives when
both system and user files set it.

## Step 5 — The parity observation (5 min)

One paragraph in your notes: if a maintainer changes only the legacy loop's
max-turns enforcement (agent.rs:2515 area) and forgets the state machine
constructions (agent.rs:1630 area), what user-visible bug appears when
`GOOSE_STATE_MACHINE=1`? Tie it to the AGENTS.md parity rule.

## Verification

```powershell
powershell -File verify.ps1 -GooseRepo $env:GOOSE_REPO
```

Expect `VERIFY PASSED`.

## Homework

- Restore your config backup (or remove the key you added) to keep a clean
  state for later labs: `Copy-Item ~\.config\goose\config.yaml.bak ~\.config\goose\config.yaml -Force`.
- Grep `GOOSE_ADDITIONAL_CONFIG_FILES` in `base.rs` and write where extra files
  are parsed and appended to `config_paths`. One sentence on why this exists
  (think: distributed/enterprise rollout).