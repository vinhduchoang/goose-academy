# Lab 1.4 — Instrument the legacy loop and record one turn's event log

Timebox: 40-50 min. PowerShell 5.1, goose checkout at `$env:GOOSE_REPO`.

Goal: place two tracing calls in the legacy loop (in your notes, optionally
applied), and record a complete event-log table of one turn with file:line
evidence for every stage.

## Step 1 — Map the entry chain (10 min)

Read in this order and record the call chain into `l04-turn-log.md`:

```text
reply (agent.rs:2020) -> reply_impl (2040) -> reply_internal (2388)
-> prepare_reply_context (855) -> [loop at 2514] -> dispatch_tool_call (1063)
```

For each hop write one line: what argument types flow in/out, and the single
most important thing the function does (from comments + code).

## Step 2 — Plant the instrument (10 min)

In `l04-turn-log.md`, show the exact snippet you would plant (do NOT build):

```rust
tracing::info!(turns_taken, max_turns, "reply turn start");
```

Choose one more spot yourself: the tool-dispatch hop. Write both snippets with
the file:line they would go between. Then justify, in one sentence each, why
`tracing::info!` (not `println!`) is the convention here — check how other
calls in the file log (search `tracing::info!` / `warn!` in agent.rs).

## Step 3 — Record one turn's event log (15 min)

Fill this table in `l04-turn-log.md` for a tool-calling turn (assistant calls
`developer__shell`, user's mode is Approve). Every row needs the evidence
file:line you found:

| # | Stage | Function / site | What happens | file:line |
|---|-------|-----------------|--------------|-----------|
| 1 | entry | reply | id boundary + stream wrapper | |
| 2 | setup | prepare_reply_context | conversation+prompt+tools assembled | |
| 3 | llm | provider complete | assistant Message back | |
| 4 | partition | categorize_tool_requests | tool requests split out | (reply_parts.rs) |
| 5 | approval | inspect_tools / permission bucket | needs_approval decides | |
| 6 | dispatch | dispatch_tool_call | hooks + execution + result | |
| 7 | append | add ToolResponse block | user-role message appended | |
| 8 | loop | turns_taken += 1 | iterate until no tool request | |

For stage 8: find the exact condition that ends the turn inside the
async_stream block — quote it.

## Step 4 — Optional live capture (10 min)

If your Unit 0 build of `goose` exists and you have any provider configured, run
a 2-message conversation with debug logs and capture the last 40 lines:

```powershell
$env:RUST_LOG = "goose=debug"
$env:GOOSE_MODE = "approve"   # or: goose configure -> set goose_mode key
cargo run -p goose-cli --bin goose -- run "Are you in approve mode?"
Remove-Item Env:RUST_LOG
Remove-Item Env:GOOSE_MODE
```

If you cannot run it live, skip this step and note *why* (no provider / no
build) — the verify script does not require the log.

## Step 5 — Legacy-path deltas (5 min)

The plan said "entry hooks -> loop -> tools (`agents/agent.rs` legacy)". Write
in `l04-turn-log.md`:

1. Which ONE planned phrase is still 100% accurate in v1.49.0?
2. Which planned file (`reply_parts.rs` era reply loop) is now a *sibling*
   rather than the loop, and where did the loop move?

## Verification

```powershell
powershell -File verify.ps1 -GooseRepo $env:GOOSE_REPO
```

Expect `VERIFY PASSED`.

## Homework

- Find `reply_with_state_machine` in agent.rs and note its line number + one
  sentence on how the same turn would enter *that* path (feeds l05).
- `CancellationToken` appears in the reply signature. Grep where it is checked
  inside the legacy loop; one sentence on what happens mid-tool-run on cancel.