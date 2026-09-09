# Lab 1.2 — Trace Message from creation to consumption; draw the flow

Timebox: 40-50 min. PowerShell 5.1, goose checkout at `$env:GOOSE_REPO`.

Goal: prove the `Message -> Vec<MessageContentBlock>` lifecycle with file evidence,
and produce a mermaid flow diagram artifact.

## Step 1 — Read the struct and its variants (10 min)

Open `crates/goose-provider-types/src/conversation/message.rs` in your editor.
Jump to lines 318 and 962. Write into `l02-flow.md`:

1. The full variant list of `MessageContentBlock` (abbreviate payloads).
2. The five fields of `Message` and the type of `role`.
3. Which field carries `#[serde(deserialize_with = ...)]` and what the
   deserializer function does to three legacy content shapes
   (search `conversationCompacted`, `reasoning`, and Unicode Tags in the file).

## Step 2 — Find the constructors (10 min)

In the same file find `impl Message` (line 971) and list the constructors you see
(`new`, `user`, `assistant`, `with_id`, ...). Then answer in `l02-flow.md`:

- Why is `with_generated_id()` needed at all, given `id` is an `Option`?
  (Hint: grep for `with_generated_id` usages under `crates/goose/src/agents/` —
  who assigns ids and when?)
- `Message::new` takes `role` — but real goose code rarely calls it. What does
  `Message::user()` do that `new` doesn't?

## Step 3 — Follow one ToolRequest through the code (15 min)

Pick the `ToolRequest` variant. Grep your way through this chain and record
`file:line` evidence for each hop in `l02-flow.md`:

1. Where is the `ToolResult` type alias defined on top of `rmcp::model::ErrorData`?
2. `crates/goose/src/agents/tool_execution.rs` — what does `ToolCallResult` become
   when a tool's result arrives (struct + `From` impl)?
3. `crates/goose/src/agents/reply_parts.rs:586` — read `categorize_tool_requests`.
   Which two buckets does it sort assistant-message content into, and what
   payload does each bucket keep?

## Step 4 — Draw the flow diagram (10 min)

Add a mermaid block at the bottom of `l02-flow.md` with the sequence:

```text
user config ──> model_config_from_user_config ──> ModelConfig
Provider::complete ──> Message(Assistant) ──> Vec<MessageContentBlock>
ToolRequest ──> tool_execution ──> ToolResponse ──> append to conversation
Session persistence ──> serde round-trip ──> deserialize_sanitized_content
```

Annotate each arrow with the file:line you verified.

## Step 5 — The drift question (5 min)

The course plan mentions `Reply / ReplyPart / ToolCall`. Grep the whole checkout:

```powershell
rg "ReplyPart" $env:GOOSE_REPO\crates --glob "*.rs"   # expect: no matches
rg "categorize_tool_requests" $env:GOOSE_REPO\crates --glob "*.rs"
```

One paragraph in `l02-flow.md`: what old-world concept does
`MessageContentBlock` replace, and why does `reply_parts.rs` still exist?

## Verification

```powershell
powershell -File verify.ps1 -GooseRepo $env:GOOSE_REPO
```

Expect `VERIFY PASSED`.

## Homework

- Add a one-variant sketch to `l02-flow.md`: a new `MessageContentBlock::Trace`
  variant + the places it would need handling (Display match, audience filter,
  formats). Estimate: how many files manually searched before you feel confident?
- Read `Message::agent_visible_content()` and explain in one sentence why
  audience filtering must live on the *model*, not the provider.