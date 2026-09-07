# Lab 1.5 — Map every ops_* file to its legacy counterpart, find parity gaps

Timebox: 40-50 min. PowerShell 5.1, goose checkout at `$env:GOOSE_REPO`.

Goal: produce the complete ops→legacy mapping table as a maintainer's mental
index (`l05-ops-map.md`), then identify parity gaps with evidence.

## Step 1 — Inventory the ops files (5 min)

```powershell
Get-ChildItem "$env:GOOSE_REPO\crates\goose\src\agents\state_machine" -Filter "ops_*.rs" |
  Select-Object Name
```

Count them. Cross-check against the module list in
`crates/goose/src/agents/state_machine/mod.rs` (lines 8-32). Record the total
in `l05-ops-map.md`.

## Step 2 — Read the executor contract (10 min)

Open `crates/goose-agent/src/machine.rs` and `operation.rs`. Answer in your
notes with line evidence:

1. `machine.rs:34` — what are the two `Step` variants, and which one ends the
   pipeline each round?
2. `machine.rs:158` — what does `run` loop over, and what decides to stop?
3. `operation.rs:74` — list the `Operation` trait's method signatures; which
   method tells the machine whether the step counts against the turn count?

## Step 3 — Build the mapping table (20 min)

For each of these ops files, find the legacy counterpart function/method in
`crates/goose/src/agents/agent.rs` (or its helpers) and one line of evidence on
each side:

| ops file | Machine step | Legacy counterpart | Evidence (file:line x2) |
|----------|--------------|--------------------|-------------------------|
| ops_llm.rs | Inference (stream) | provider complete / stream call in reply loop | |
| ops_toolcalling.rs | ToolExecutionOperation (:734) | dispatch_tool_call (:1063) | |
| ops_compaction.rs | CompactionOperation (:47) | compaction inside the legacy loop (find it) | |
| ops_maxturns.rs | MaxTurnsOperation | max_turns read + check (:2515 area) | |
| ops_doctor.rs | DoctorOperation | doctor hook in legacy (find it) | |
| ops_steer.rs | SteerOperation | steer_queue handling in reply loop | |
| ops_retry.rs | RetryOperation | handle_retry_logic (:824) | |
| ops_stop_hook.rs | StopHookOperation | stop-hook checks near loop exit | |
| ops_tool_approval.rs | ToolApprovalOperation | inspect_tools + permission buckets (:2836) | |
| ops_slash_command.rs | SlashCommandOperation | legacy slash-command handling | |

Hints: use `rg -n "fn <name>"` and `rg -n "Operation::new"` in
`crates\goose\src\agents`. For the legacy side, search the loop body for the
same *concept* (doctor, steer, stop hook) rather than the same name.

## Step 4 — Find a parity gap (10 min)

Pick one row where the machine-side implementation and the legacy side show a
visible *difference* (e.g. hardcoded message text, different fallback default,
or a check that exists only once). Write in `l05-ops-map.md`:

- the row,
- the exact differing two lines (copied),
- the user-visible behavior difference under `GOOSE_STATE_MACHINE=1` vs `0`,
- which path you think is correct.

## Step 5 — The effects split (5 min)

Read `crates/goose/src/agents/state_machine/effects.rs:8` and
`session.rs:40` (`apply_effects`). One paragraph: name 2 `GooseEffect`
variants and say which goose state each mutates through the `SessionManager`
handler.

## Verification

```powershell
powershell -File verify.ps1 -GooseRepo $env:GOOSE_REPO
```

Expect `VERIFY PASSED`.

## Homework

- `GOOSE_STATE_MACHINE` gate: read `state_machine/mod.rs:73` and write the
  exact env values that enable the machine.
- Open `AGENTS.md` (goose repo root) and find the section that mandates
  legacy/state-machine parity. Copy its key sentence into `l05-ops-map.md` —
  you will cite it again in Unit 2.