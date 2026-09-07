# Lab 3.2 — Build a working echo provider in ~150 lines

Timebox: 40-50 min. PowerShell 5.1 against your goose checkout
(`$env:GOOSE_REPO`). No provider code ships inside the goose repo — your
crate is standalone and points at goose with a **path dependency**.

## Step 1 — Scaffold the crate (5 min)

```powershell
$env:LAB02 = Join-Path (Get-Location) "goose-labs\u3-l02"
cargo new --lib echo-ext
Move-Item -Force echo-ext $env:LAB02
Set-Location $env:LAB02\echo-ext
```

Open `Cargo.toml` and make it depend on the provider types crate:

```toml
[package]
name = "echo-ext"
version = "0.1.0"
edition = "2021"

[dependencies]
async-trait = "0.1"
futures = "0.3"
goose-provider-types = { path = "C:/Users/admin/projects/goose/crates/goose-provider-types" }

[dev-dependencies]
# stay empty for now - the test uses the runtime the library already pulls
```

## Step 2 — Read the contract you must satisfy (10 min)

Read these before writing code, note the line numbers in `u3-l02-notes.md`:

- `crates/goose-provider-types/src/base.rs:464` — the `Provider` trait
- `crates/goose-provider-types/src/base.rs:477` — `stream` signature = your job
- `crates/goose-provider-types/src/base.rs:485` — `complete` default (read it!)
- `crates/goose-provider-types/src/base.rs:327` — `MessageStream` type alias
- `crates/goose-provider-types/src/conversation/message.rs:318` — enclosure types

Answer in notes: which two things does the default `complete` call, in order?

## Step 3 — Write the echo provider (15 min)

Replace `src/lib.rs` entirely. Sketch (complete it yourself — the spec is the
trait, not this snippet):

```rust
use async_trait::async_trait;
use futures::StreamExt;
use goose_provider_types::base::{
    stream_from_single_message, MessageStream, Provider, ProviderDescriptor, ProviderMetadata,
};
use goose_provider_types::conversation::message::{Message, MessageContentBlock};
use goose_provider_types::conversation::token_usage::{ProviderUsage, Usage};
use goose_provider_types::errors::ProviderError;

pub struct EchoProvider { pub name: String }

impl ProviderDescriptor for EchoProvider {
    fn metadata() -> ProviderMetadata { /* name, display name, default model */ }
}

#[async_trait]
impl Provider for EchoProvider {
    fn get_name(&self) -> &str { &self.name }

    async fn stream(
        &self,
        _model_config: &goose_provider_types::model::ModelConfig,
        _system: &str,
        messages: &[Message],
        _tools: &[goose_provider_types::rmcp::model::Tool],
    ) -> Result<MessageStream, ProviderError> {
        // 1. find the last user message text (MessageContentBlock::Text)
        // 2. echo it back as an assistant Message
        // 3. count tokens by splitting on whitespace -> Usage
        // 4. return stream_from_single_message(message, usage)
        todo!("replace with your implementation")
    }
}
```

Rules: return an assistant `Message` whose content is one
`MessageContentBlock::Text` echoing the last user text; set `input_tokens`
and `output_tokens` from a whitespace token count. That completes the loop —
no network, no model, still a real `Provider`.

## Step 4 — Test `complete()` (10 min)

Add a test module inside `lib.rs` (or `tests/`) with `#[tokio::test]` that:

1. builds `EchoProvider`,
2. builds a user `Message` — see how `TestProvider`'s test makes one at
   `crates/goose/src/providers/testprovider.rs:248`,
3. awaits `provider.complete(&model_config, system, messages, &[])`,
4. asserts the reply text equals the input text and `usage.output_tokens` is
   `Some(_)`.

If tokio is missing for tests, add `tokio = { version = "1", features = ["macros", "rt"] }`
to `[dev-dependencies]` — that's expected and normal.

## Step 5 — Compare with the repo's own test provider (10 min)

Read `crates/goose/src/providers/testprovider.rs` through line 220 and write in
notes: (a) what purpose does `hash_input` serve, (b) why does the replay path
return an error when the hash is unknown, and (c) one way echo's `stream` is
simpler than `TestProvider::stream`.

## Verification

```powershell
powershell -File verify.ps1 -LabDir $env:LAB02 -GooseRepo $env:GOOSE_REPO
```

Optional (not required by the checker): `cargo check` inside `echo-ext` — first
run compiles the provider-types dependency tree, expect a few minutes.

## Homework

- Make the echo response configurable: if the user message starts with
  `upper:`, uppercase the echo. Add a second test proving both paths.
- List every `Provider` method that has a default body, from the trait source,
  with one line on what each is for.