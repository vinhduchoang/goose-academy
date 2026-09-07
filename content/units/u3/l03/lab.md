# Lab 3.3 — Add streaming, accounting, cost, telemetry to the echo

Timebox: 40-50 min. PowerShell 5.1, your goose checkout (`$env:GOOSE_REPO`).
Reuse the `echo-ext` crate from Lab 3.2.

```powershell
$env:LAB03 = Join-Path (Get-Location) "goose-labs\u3-l03"
# copy your l02 crate forward so you evolve one codebase
Copy-Item -Recurse -Force (Join-Path (Get-Location) "goose-labs\u3-l02\echo-ext") $env:LAB03
Set-Location (Join-Path $env:LAB03 "echo-ext")
```

## Step 1 — Stream word-by-word (15 min)

Change `stream` to yield **multiple** chunks. Keep the signature — the change
is internal:

```rust
use futures::stream;
use std::time::{Duration, Instant};

async fn stream( ... ) -> Result<MessageStream, ProviderError> {
    let reply = /* the echoed text */;
    let started = Instant::now();
    let words: Vec<&str> = reply.split_whitespace().collect();

    let mut partial = String::new();
    let chunks: Vec<Result<(Option<Message>, Option<ProviderUsage>), ProviderError>> =
        words.iter().map(|w| {
            partial.push_str(w);
            partial.push(' ');
            let delta = Message::new(
                rmcp::model::Role::Assistant,
                chrono::Utc::now().timestamp(),
                vec![MessageContentBlock::text(partial.clone())],
            );
            Ok((Some(delta), None))
        }).collect();
    // final chunk: usage only
    let usage = /* ProviderUsage with counts + time_to_first_token_ms */;
    let chunks = ...;
    Ok(Box::pin(stream::iter(chunks)))
}
```

Rules: each delta emits the cumulative text (mirroring how `collect_stream`
coalesces); the *last* chunk is `(None, Some(usage))`.

## Step 2 — Chat-shaped token counting (10 min)

Your naive whitespace count from l02 is what l03 retires. Read
`crates/goose/src/token_counter.rs:129` (`count_chat_tokens`) and
`crates/goose/src/providers/usage_estimator.rs:9` (`ensure_usage_tokens`).
Answer in `u3-l03-notes.md`:

1. What is the exact order of the fallback: which fields are checked before the
   counter is created?
2. What happens when both counts are already present?

Then implement `fn estimate_chat_tokens(system: &str, messages: &[Message]) -> i32`
in your lib that counts **words per role segment** (system, then each message)
and adds a fixed 4-token chat-template overhead per message — log it in notes as
an approximation of the real counter ("real one is tiktoken-style; mine is a
chat-shaped approximation").

## Step 3 — Price the call + time the tokens (10 min)

Add to lib.rs (below the provider):

```rust
pub struct LinearPricing { pub input_per_mtok: f64, pub output_per_mtok: f64 }

pub fn estimate_cost(pricing: &LinearPricing, usage: &Usage) -> f64 {
    // per-1M-token rates -> USD
    todo!("divide counts by 1_000_000, multiply by rates, sum input+output")
}
```

Read the precedence comment at `crates/goose/src/providers/canonical_cost.rs:1`
and copy its 4-tier order into your notes. Then populate `ProviderStats`:
`time_to_first_token_ms`, `elapsed_ms` (use `Instant` from Step 1).

## Step 4 — gen_ai-style usage span (10 min)

In your test module, add a test that mimics `record_usage`
(`crates/goose/src/agents/gen_ai_telemetry.rs:52`): build a small
`std::collections::HashMap<&str, String>` of attributes, insert
`gen_ai.usage.input_tokens` and `gen_ai.usage.output_tokens`, and assert both
are non-empty. (You're replicating the pattern, not linking OTel — note why in
`u3-l03-notes.md`: content capture must remain opt-in like
`OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT`.)

## Verification

```powershell
powershell -File verify.ps1 -LabDir $env:LAB03 -GooseRepo $env:GOOSE_REPO
```

Optional: `cargo check` inside the crate.

## Homework

- Read `collect_stream` (`base.rs:365`) and write in notes: why does a
  multi-block chunk (text + thinking) *not* get absorbed into the prior
  message's last block?
- Grep the repo for `gen_ai.usage.` — which file other than gen_ai_telemetry.rs
  writes these attributes, and when?