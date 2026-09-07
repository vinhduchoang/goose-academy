# Lab 1.9 — Cross-server schema collision drill

Timebox: 40-50 min. PowerShell 5.1, goose checkout at `$env:GOOSE_REPO`.

Goal: prove you understand what happens when two MCP servers publish conflicting
tool schemas — by reading the normalization layer and simulating the collision.

## Step 1 — The client seam (10 min)

Open `crates/goose/src/agents/mcp_client.rs`. In `l09-mcp-notes.md`:

1. Copy the `McpClientTrait` signature list (line 108 area) — which methods must
   every MCP caller implement? Which one sends a tool call?
2. `GooseClient` (line 206) implements rmcp's `ClientHandler` (line 392). Read
   30 lines of that impl: name one thing goose does *during* a tool call that a
   bare rmcp client would not.
3. Where does `MCP_PROTOCOL_VERSION` (agent.rs:102) get consulted during
   connect? (Grep for it — include the line in your notes.)

## Step 2 — The server side in one file (10 min)

1. `crates/goose-mcp/src/mcp_server_runner.rs:39` — copy the `serve` function
   body parts: transport, error handling on serve failure.
2. `crates/goose-mcp/src/lib.rs` — find `APP_STRATEGY` and `BUILTIN_EXTENSIONS`.
   What does the static map's `SpawnServerFn` type say about how builtins are
   launched (in-proc or spawn)?

## Step 3 — Read the normalizers (15 min)

`crates/goose/src/agents/tool_schema_normalize.rs`. For each function below,
write in your notes: what input shape triggers it, and what output it produces:

1. `normalize_input_schema` (line 6)
2. `collapse_const_unions` (line 26) — sketch a before/after JSON snippet
3. `inline_refs` (line 271) — why do some *providers* need this?
4. `percent_decode` (line 350) — which servers emit this shape?

## Step 4 — The collision drill (10 min)

Simulate the conflict on paper (do not run servers). In `l09-collision.md`:

Server A publishes tool `list_dir` with schema
`{"properties":{"path":{"type":"string"},"max":{"type":"integer"}}}`.
Server B (built-in namespaced as `ext2__list_dir`) publishes the *same* tool
name with `{"properties":{"path":{"type":"array"}}}` plus a `$ref` to
`"#/$defs/filter"` that never gets defined.

Answer with code evidence:

1. Are the two tools guaranteed distinct? (Cite `get_prefixed_tools` from l08.)
2. How does the *model* see each schema — trace where normalization happens
   relative to prefixing (find the caller of `normalize_input_schema`).
3. Server B's dangling `$ref`: what does `inline_refs` do to it, and what would
   the provider receive if normalization were skipped?
4. Which file would you change to add a diagnostic log for "schema changed
   after normalization"? Write the 2-line patch (no build needed).

## Verification

```powershell
powershell -File verify.ps1 -GooseRepo $env:GOOSE_REPO
```

Expect `VERIFY PASSED`.

## Homework

- Grep `V_2025_` across `crates/` — one line each: which protocols coexist in
  this workspace (MCP + ACP)?
- Read `crates/goose/src/mcp_utils.rs:7` (`extract_text_from_resource`). One
  sentence: why does every MCP client need a resource-text extractor?