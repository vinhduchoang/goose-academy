# Lab 1.8 — Follow one extension from disk to live tool, step by step

Timebox: 40-50 min. PowerShell 5.1, goose checkout at `$env:GOOSE_REPO`.

Goal: produce a hop-by-hop, file:line-annotated trace of how the bundled
`memory` extension becomes a callable tool, then generalize it for a stdio
extension of your own.

## Step 1 — Find the starting config (10 min)

1. Open `crates/goose/src/config/extensions.rs:301`
   (`resolve_extensions_for_new_session`). Copy its return signature into
   `l08-extension-trace.md`.
2. Search `crates/goose-mcp/src/lib.rs` for how the built-in `memory` server is
   registered in the static map (around line 57). Which crate hosts the memory
   *implementation* (`crates/goose-mcp/src/memory/`)?

## Step 2 — Read one ExtensionConfig variant fully (10 min)

`crates/goose/src/agents/extension.rs:161`. In your notes:

1. Copy the fields of the `Stdio` variant (name, cmd, args, envs, timeout…) —
   as seen in the code.
2. Read `validate()` (a few lines above the enum impl). Name 3 of the
   `DISALLOWED_KEYS` values. Why does the system forbid extensions from
   overriding those env vars?
3. What does `read_timeout`/`timeout` (whichever exists on the variant) cap?

## Step 3 — Trace spawn through the manager (10 min)

Open `crates/goose/src/agents/extension_manager.rs`. Find (grep `iko`/`stdio`/
`spawn`) the function that actually spawns a stdio server process and
establishes the MCP client connection. Answer with evidence:

1. Which function spawns, and which library handles the wire protocol — find
   the `rmcp` import/usage on that path (this feeds l09).
2. `get_tool_owner` (`extension_manager.rs:276`): how does a `Tool` struct get
   attached to its owning extension (what does the function inspect)?

## Step 4 — The malware gate at spawn (5 min)

`crates/goose/src/agents/extension_malware_check.rs:76` — read `deny_if_malicious`
and its friend (`deny_if_malicious_cmd_args`, line 44). In your notes: what
signal does each scan, and what error type gets returned on denial? One
sentence on where this check runs *again* for the whole bundled set at startup.

## Step 5 — Load into the agent (10 min)

`crates/goose/src/agents/agent.rs:1338` — read `add_extension`. In
`l08-extension-trace.md`, write the final chain with line numbers for EACH hop
(>= 6 hops), ending in dispatch:

```text
config/extensions.rs resolve -> agent.rs add_extension -> extension_manager.rs
(registry/spawn) -> mcp client connect -> get_prefixed_tools ->
prepare_tools_for_provider -> dispatch_tool_call (l07)
```

For each hop one line: what type goes in / out. Skip none — TypeDrift between
hops is the point.

## Step 6 — Generalize (5 min)

One paragraph: given a *new* stdio extension at `C:\myext\ext.exe`, which config
file (read `config/extensions.rs` for where extensions are stored) do you edit,
what JSON shape do you add (copy the field names you saw in Step 2), and which
of the 4 stages would reject a malicious `cmd`?

## Verification

```powershell
powershell -File verify.ps1 -GooseRepo $env:GOOSE_REPO
```

Expect `VERIFY PASSED`.

## Homework

- `is_first_class_extension` (`extension_manager.rs:404`) — write in your notes
  which names are first-class today and one sentence on what being first-class
  buys (search usages).
- Grep `ExtensionLoadResult` in agent.rs (exported at agents/mod.rs:29). Name
  its variants — they are the load-phase outcome contract you will map in Unit 3.