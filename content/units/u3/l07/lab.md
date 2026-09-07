# Lab 3.7 — Harden `notes-server`: bad input, timeouts, elicitation, auth

Timebox: 40-50 min. PowerShell 5.1, your goose checkout (`$env:GOOSE_REPO`).
Reuse l06's crate.

```powershell
$env:LAB07 = Join-Path (Get-Location) "goose-labs\u3-l07"
Copy-Item -Recurse -Force (Join-Path (Get-Location) "goose-labs\u3-l06\notes-server") $env:LAB07
Set-Location (Join-Path $env:LAB07 "notes-server")
```

## Step 1 — Read the outcome alphabet (10 min)

Before writing code, note in `u3-l07-notes.md`:

- `crates/goose/src/action_required_manager.rs:16` — the three `ElicitationOutcome`
  variants and what data `Accept` carries.
- `crates/goose/src/elicitation.rs:16` — how each outcome maps into
  `ElicitationAction`.
- `crates/goose/src/config/extensions.rs:10` — the default extension timeout.

## Step 2 — Bounded input + informative errors (15 min)

Add to `add_note`:

1. `MAX_NOTE_LEN = 500` — reject longer notes with `INVALID_PARAMS` and a
   message stating the limit and the received length.
2. A tag allowlist: tags must match `^[a-z0-9-]{1,32}$` — reject otherwise,
   message shows the failing tag.
3. An `els` guard so note ids cannot be `..`-style paths (think: the note
   filename must be server-generated, never user-controlled).

Each failure returns `ErrorData::new(ErrorCode::INVALID_PARAMS, "...", None)`.

## Step 3 — A bounded slow operation + timeout (10 min)

Add a tool that reads a large file but must give up:

```rust
use tokio::time::{timeout, Duration};

#[tool(name = "search_notes", description = "Search saved notes; gives up after a bounded wait")]
pub async fn search_notes(
    &self,
    params: Parameters<SearchParams>,
    _context: RequestContext<RoleServer>,
) -> Result<CallToolResult, ErrorData> {
    let deadline = Duration::from_secs(5);
    match timeout(deadline, self.slow_scan(params.0.query.clone())).await {
        Ok(Ok(hits)) => Ok(CallToolResult::success(vec![ContentBlock::text(hits)])),
        Ok(Err(e))  => Err(ErrorData::new(ErrorCode::INTERNAL_ERROR, e.to_string(), None)),
        Err(_)      => Err(ErrorData::new(ErrorCode::INTERNAL_ERROR, "search timed out after 5s".into(), None)),
    }
}
```

`slow_scan` just sleeps, then scans. Add `#[derive(Debug, Serialize, Deserialize, JsonSchema)]`
`SearchParams { query: String }`. Note why only *interruptible, cancel-safe*
work belongs inside a `tokio::time::timeout`.

## Step 4 — Elicitation (10 min)

Add `confirm_overwrite` — before replacing the notes file, it must get a human
yes. Sketch (adjust to the rmcp API in your checkout):

```rust
#[tool(name = "confirm_overwrite", description = "Ask the user before destructive overwrite")]
pub async fn confirm_overwrite(
    &self,
    _params: Parameters<ConfirmParams>,
    context: RequestContext<RoleServer>,
) -> Result<CallToolResult, ErrorData> {
    // sever->client ask; goose surfaces it via ActionRequired/ElicitationOutcome
    let answer = context
        .client()
        .request_elicitation(...)
        .await
        .map_err(|e| ErrorData::new(ErrorCode::INTERNAL_ERROR, format!("elicit failed: {e}"), None))?;
    match answer {
        rmcp::model::ElicitationAction::Accept => { /* overwrite */ }
        rmcp::model::ElicitationAction::Decline => Ok(CallToolResult::success(vec![ContentBlock::text("user declined; notes unchanged")])),
        rmcp::model::ElicitationAction::Cancel => Ok(CallToolResult::success(vec![ContentBlock::text("cancelled")])),
    }
}
```

In notes: which goose enum consumes this answer (`ElicitationOutcome`) and
which file converts it back (`crates/goose/src/elicitation.rs`).

## Step 5 — Auth boundary (10 min)

Add `fn check_auth(meta: &MetaObject) -> Result<(), ErrorData>` that:

- reads an `authorization` header from `meta` (`Bearer <token>`),
- requires a configured `NOTES_TOKEN` env var,
- returns `ErrorData::new(ErrorCode::INVALID_REQUEST, "missing or bad token", None)`
  otherwise,

and call it at the top of `add_note` and `confirm_overwrite`. Wire
`env_keys: [NOTES_TOKEN]` into `u3-l07-ext.yaml`. Note in `u3-l07-notes.md`
the two auth doors (stdio headers vs streamable_http `AuthRequired` +
`create_streamable_http_client` at `crates/goose/src/agents/extension_manager.rs:1105`).

## Step 6 — Tests for every failure branch (10 min)

Add `#[test]`/`#[tokio::test]` fns covering: too-long note, bad tag, empty
text, auth rejection, timeout branch (make `slow_scan` sleep long in test
mode), and declined elicitation. Make them unit test the *validation logic*
(extract pure `fn validate_note(text, tag) -> Result<(), String>` to keep
tests cheap — note that as the hardening pattern).

## Verification

```powershell
powershell -File verify.ps1 -LabDir $env:LAB07 -GooseRepo $env:GOOSE_REPO
```

## Homework

- Find where `is_error` tool results are flagged for the transcript (search
  goose repo for `is_error`) and write one sentence on how the agent sees a
  hardened error.
- Read `crates/goose/src/plugins/mcp_servers.rs:171` — list the structural
  requirements a config `.mcp.json` must satisfy.