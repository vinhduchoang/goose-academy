# Lab 1.10 — Force a compaction; verify history survives

Timebox: 40-50 min. PowerShell 5.1, goose checkout at `$env:GOOSE_REPO`.

Goal: trace the full compaction decision -> summary -> splice path, and prove
by code reading (plus an optional targeted test run) that history survives the
splice.

## Step 1 — The threshold chain (10 min)

In `l10-context-notes.md`, trace with file:line:

1. `crates/goose/src/context_mgmt/mod.rs:225` — what inputs does
   `check_if_compaction_needed` take and what does it compute to say yes?
2. Where does `GOOSE_AUTO_COMPACT_THRESHOLD` get read (`crates/goose/src/agents/agent.rs:1650`)?
   What is the default (find `DEFAULT_COMPACTION_THRESHOLD` in
   `goose-context-management`)?
3. `crates/goose/src/context_limit.rs:12` vs
   `crates/goose-provider-types/src/context_limit.rs:9` — which one wins in the
   Provider default method, and in what order are override/config/canonical
   consulted? (Cite the resolver method.)

## Step 2 — Read the compaction brain (15 min)

`crates/goose-context-management/src/`:

1. `summarize.rs:124` — what goes in (types), what comes out, and which model
   calls it (the `CompactionModel` trait in `model.rs:13`)?
2. `templates.rs` + `prompts/compaction.md` — copy the first 3 lines of the
   template. Whose voice does the summary adopt?
3. In `crates/goose/src/context_mgmt/mod.rs:70` (`compact_messages`) — what
   happens to the *original* messages after the summary is produced? Find the
   splice: which messages are replaced, which survive untouched (the tail)?

## Step 3 — The state-machine twin + the cap (10 min)

1. `crates/goose/src/agents/state_machine/ops_compaction.rs:47` —
   `CompactionOperation`: how does it decide to apply? (Which limit does it
   compare?)
2. Same file line 24: `MAX_CONTEXT_ERROR_COMPACTIONS = 2`. What error triggers
   *error* compactions (they're distinct from threshold compactions)? Write
   what happens on the third one.

## Step 4 — Prove history survives (10 min)

Option A (code proof): find the tests for compaction
(`context_mgmt` tests and/or `goose-context-management`), copy one test name
that asserts original content survives in the post-compaction conversation.

Option B (run, if your Unit 0 build exists — single targeted test only):

```powershell
Set-Location $env:GOOSE_REPO
cargo test -p goose-context-management model:: 2>$null   # adjust to a test name from Option A
```

Paste the PASSED line into `l10-context-notes.md`. This is the one optional
build the course allows here; skipping it is fine — note why.

## Step 5 — History search against compacted data (5 min)

`crates/goose/src/session/chat_history_search.rs:50` — answer in your notes:
if a fact from turn 3 got summarized away, can chat history search still find
the fact *word-for-word*? Trace what the search reads (compacted conversation
vs raw log) and state the honest answer with evidence.

## Verification

```powershell
powershell -File verify.ps1 -GooseRepo $env:GOOSE_REPO
```

Expect `VERIFY PASSED`.

## Homework

- `tool_pair_summarization_enabled` / `summarize_tool_call`
  (`context_mgmt/mod.rs:445` area): one sentence on what tool-pair
  summarization compacts, and why it exists *in addition* to full compaction.
- Find `last_message_snippet` in session_manager.rs and write how it is
  maintained (when is it updated?) — it's the tiny optimization that keeps
  session lists cheap.