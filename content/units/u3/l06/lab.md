# Lab 3.6 — Build `notes-server`: MCP tools callable from goose

Timebox: 40-50 min. PowerShell 5.1, your goose checkout (`$env:GOOSE_REPO`).

```powershell
$env:LAB06 = Join-Path (Get-Location) "goose-labs\u3-l06"
New-Item -ItemType Directory -Force -Path $env:LAB06 | Out-Null
Set-Location $env:LAB06
```

## Step 1 — Study the reference server (10 min)

Read `crates/goose-mcp/src/memory/mod.rs` and note in `u3-l06-notes.md`:

1. The three parts of `MemoryServer` (struct fields at line 104, router macro
   at line 116, tool macro at line 390).
2. What `Parameters<RememberMemoryParams>` gives a tool (typed, schema-validated
   args) and what `RequestContext<RoleServer>` carries (per-call meta).
3. What `instructions` text is for, in one sentence.

## Step 2 — Scaffold your server crate (5 min)

```powershell
cargo new notes-server
Set-Location notes-server
```

`Cargo.toml`:

```toml
[package]
name = "notes-server"
version = "0.1.0"
edition = "2021"

[dependencies]
anyhow = "1"
rmcp = { version = "3", default-features = false, features = ["server", "macros", "transport-io", "schemars"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
tokio = { version = "1", features = ["rt-multi-thread", "macros"] }
tracing = "0.1"
```

## Step 3 — Write the server (15 min)

`src/main.rs`: an `add_note` tool (params: `text: String`, optional `tag`) that
appends a line to `<cwd>/.notes/notes.txt`; a `list_notes` tool that returns the
file. Model it line-for-line on MemoryServer:

```rust
use rmcp::{
    handler::server::{router::tool::ToolRouter, wrapper::Parameters},
    model::{CallToolResult, ContentBlock, ErrorData, ErrorCode},
    schemars::JsonSchema,
    service::RequestContext,
    tool, tool_router, RoleServer, ServerHandler,
};
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
pub struct AddNoteParams { pub text: String, #[serde(default)] pub tag: Option<String> }

#[derive(Clone)]
pub struct NotesServer { tool_router: ToolRouter<Self>, instructions: String }

#[tool_router(router = tool_router)]
impl NotesServer {
    pub fn new() -> Self { /* build router + instructions */ }

    #[tool(name = "add_note", description = "Append a short note ...")]
    pub async fn add_note(
        &self,
        params: Parameters<AddNoteParams>,
        _context: RequestContext<RoleServer>,
    ) -> Result<CallToolResult, ErrorData> {
        if params.0.text.trim().is_empty() {
            return Err(ErrorData::new(ErrorCode::INVALID_PARAMS, "note text must not be empty".into(), None));
        }
        // write the note; return CallToolResult::success(vec![ContentBlock::text("note saved")])
        todo!("implement")
    }

    // no-parameter tool: if rmcp 3 rejects `()`, use a zero-field params struct
    #[tool(name = "list_notes", description = "List all saved notes ...")]
    pub async fn list_notes(
        &self,
        _context_or_params: (),
    ) -> Result<CallToolResult, ErrorData> {
        todo!("implement")
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let server = NotesServer::new();
    let service = rmcp::service::serve_directly(server, rmcp::transport::stdio(), None);
    service.waiting().await?;
    Ok(())
}
```

Wire it up per `crates/goose-mcp/examples/mcp.rs:31` for the serve calls, and
`crates/goose-mcp/src/memory/mod.rs:390` for the tool macro syntax. Fill the
`todo!()`s (a `std::fs::OpenOptions` append is fine).

## Step 4 — Tools live in goose: config wiring (10 min)

Write `u3-l06-ext.yaml` — the exact entry goose's ExtensionManager will spawn:

```yaml
extensions:
  notes:
    enabled: true
    type: stdio
    cmd: notes-server
    args: []
    timeout: 300
```

In notes answer: (a) which field tells goose this is a subprocess extension,
(b) why `timeout` matters for a tool that writes files, (c) what happens on
the goose side at spawn — connect it to `create_stdio...` in
`crates/goose/src/agents/extension_manager.rs` around line 800 and the
`McpClient` at `crates/goose/src/agents/mcp_client.rs:639` (write the file:line
refs you find).

## Step 5 — Live handshake evidence (5 min, optional but encouraged)

If you have a compiled goose, run:

```powershell
$env:GOOSE_REPO = "C:\Users\admin\projects\goose"
# builtin reference: cargo run -p goose-cli --bin goose -- mcp memory   (build takes a while; skip if out of time)
```

Otherwise: paste the output of `Select-String -Path (Join-Path $env:GOOSE_REPO "crates\goose-cli\src\cli.rs") -Pattern "handle_mcp_command"` into
notes as the live-command evidence.

## Verification

```powershell
powershell -File verify.ps1 -LabDir $env:LAB06 -GooseRepo $env:GOOSE_REPO
```

## Homework

- List every rmcp feature flag `goose-mcp` enables in its Cargo.toml and one
  sentence each on why a client-server extension needs `macros`.
- Compare `serve_directly` (examples) vs `serve` in
  `crates/goose-mcp/src/mcp_server_runner.rs:47` — what does the runner version
  add?