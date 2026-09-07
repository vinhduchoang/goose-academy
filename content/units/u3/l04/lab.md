# Lab 3.4 — Emit OpenAI/Anthropic envelopes; round-trip tool calls

Timebox: 40-50 min. PowerShell 5.1, your goose checkout (`$env:GOOSE_REPO`).
Reuse the crate from l02/l03 in a fresh l04 copy.

```powershell
$env:LAB04 = Join-Path (Get-Location) "goose-labs\u3-l04"
Copy-Item -Recurse -Force (Join-Path (Get-Location) "goose-labs\u3-l03\echo-ext") $env:LAB04
Set-Location (Join-Path $env:LAB04 "echo-ext")
```

If your Cargo.toml lacks serde_json, add `serde_json = "1"`.

## Step 1 — Read the two response mappers (10 min)

Open both files side by side and note in `u3-l04-notes.md`:

- `crates/goose-provider-types/src/formats/openai.rs:761` — the
  `tool_calls` branch. What three fields does the mapper extract per call?
- `crates/goose-provider-types/src/formats/anthropic.rs:557` — list the
  content-block types the Anthropic mapper handles, and what it does when a
  `tool_result` has no preceding `tool_use`.
- What's different about the *id* field between formats? (OpenAI id lives on the
  call; Anthropic ids pair `tool_use_id` on the result.)

## Step 2 — Add an `envelope` module to your crate (15 min)

Create `src/envelope.rs` (declare `pub mod envelope;` in lib.rs) with two
pure functions — no HTTP:

```rust
pub fn to_openai_tool_call(request: &ToolRequest) -> serde_json::Value
// -> {"id": <id>, "type": "function",
//     "function": {"name": <name>, "arguments": <arguments as JSON STRING>}}

pub fn from_openai_tool_call(value: &serde_json::Value) -> anyhow::Result<ToolRequest>
// -> inverse parse: id, name, then serde_json::from_str the arguments string
```

Use `goose_provider_types::conversation::message::ToolRequest` — check its
fields at `crates/goose-provider-types/src/conversation/message.rs:133`. The
critical rule you must replicate from the real mapper: `arguments` is a JSON
**string** on the wire, parsed into a `Value` inside the `ToolRequest`.

## Step 3 — Anthropic side (10 min)

Add to `envelope.rs`:

```rust
pub fn to_anthropic_tool_use(request: &ToolRequest) -> serde_json::Value
// -> {"type": "tool_use", "id": <id>, "name": <name>, "input": <arguments as OBJECT>}

pub fn from_anthropic_tool_use(value: &serde_json::Value) -> anyhow::Result<ToolRequest>
// -> input arrives as an object, NOT a string - the asymmetry to call out
```

Write one sentence in notes comparing the two `arguments` encodings (string vs
object) and why guessing wrong silently breaks tool calls.

## Step 4 — Round-trip tests (10 min)

In `tests/roundtrip.rs`, add:

1. an OpenAI round trip: build a `ToolRequest` (id `call_1`, name `shell`,
   arguments `{"cmd":"echo hi"}`), `to_openai_tool_call` → assert the
   `function.arguments` field is a JSON string → `from_openai_tool_call` →
   assert id/name/arguments equal the original;
2. an Anthropic round trip with the same request, asserting `input` is an
   object;
3. a malformed-input test: `from_openai_tool_call` on arguments `"not json"`
   must return `Err`, mirroring how the real mapper surfaces parse failures.

## Step 5 — Cite the repo evidence (5 min)

Run these greps and paste the hits into `u3-l04-notes.md`:

```powershell
Select-String -Path (Join-Path $env:GOOSE_REPO "crates\goose-provider-types\src\formats\openai.rs") -Pattern 'pub fn response_to_message'
Select-String -Path (Join-Path $env:GOOSE_REPO "crates\goose-provider-types\src\formats\anthropic.rs") -Pattern 'TOOL_USE_TYPE|tool_use_id'
```

## Verification

```powershell
powershell -File verify.ps1 -LabDir $env:LAB04 -GooseRepo $env:GOOSE_REPO
```

Optional: `cargo test` — your round-trip tests compile without any OTel/tokio
runtime surprises (`anyhow` may need adding: `anyhow = "1"`).

## Homework

- `crates/goose-provider-types/src/formats/openai.rs:566`: why must
  `merge_split_tool_call_messages` exist? What request shape do ReST APIs
  reject without it?
- Grep `get_cost` in the same file and explain where provider-reported cost is
  cached on `ProviderUsage`.