# Lab 2.4 — Write a provider test with a mock; study the record-replay seam

Timebox: 40-50 min. Scratch crate under `$env:U2LABS`, clone reading, no heavy
builds.

## Step 1 — Read the doctrine where it lives (10 min)

In the clone, read:

1. `AGENTS.md:93` — the placement rule. One sentence in notes: what counts as
   "prefer `tests/`" and what belongs in `src` unit modules.
2. `crates/goose/tests/mcp_integration_test.rs:44-90` — the inline
   `MockProvider`. Which trait(s) does it implement? Which methods are
   actually exercised by the test?
3. `crates/goose-test-support/src/mcp.rs:16-60` — list the tools
   `McpFixtureServer` exposes and what `FAKE_CODE` returns.

Save answers in `$env:U2LABS\u2-l04-notes.md`.

## Step 2 — Build a mock provider in scratch (18 min)

```powershell
Set-Location $env:U2LABS
cargo new --lib u2-l04-scratch
Set-Location u2-l04-scratch
cargo add tokio --features full
```

Model the real `Provider` seam in `src/lib.rs` — a trait, a mock, and the
message plumbing (approximate the shapes honestly, no copy-paste of goose
internals):

```rust
pub struct FakeMessage { pub text: String }

pub trait ChatProvider: Send + Sync {
    fn name(&self) -> &str;
    fn complete(&self, prompt: &str) -> FakeMessage;
}

pub struct MockProvider {
    pub canned: String,
}

impl MockProvider {
    pub fn new(canned: impl Into<String>) -> Self {
        Self { canned: canned.into() }
    }
}

impl ChatProvider for MockProvider {
    fn name(&self) -> &str { "mock" }
    fn complete(&self, _prompt: &str) -> FakeMessage {
        FakeMessage { text: self.canned.clone() }
    }
}
```

Then add **two** tests where the doctrine says:

- `tests/mock_provider_test.rs` — integration test: construct `MockProvider`,
  call `complete`, assert the canned text comes back and the name is
  `"mock"`. Use `#[tokio::test]`-free plain `#[test]` (no async needed yet).
- one `#[cfg(test)]` unit test inside `src/lib.rs` testing a pure helper you
  add: `fn usage_chars(msg: &FakeMessage) -> usize` returning the length of
  `text.chars()`.

Run `cargo test` — both layers green.

## Step 3 — The record-replay seam (15 min)

In the clone, `Get-ChildItem crates/goose/tests/mcp_replays` — count the
files and open the first lines of one replay. Then read `Justfile:456-458`.

Answer in `u2-l04-notes.md`:

1. What are the three things `just record-mcp-tests` does, in order?
2. `mcp_integration_test.rs:199` — what does record mode write, and what does
   replay mode read instead?
3. Why are replays committed to git (replay rot) and why does
   `.gitignore` exclude `*errors.txt` files under `mcp_replays`?

## Step 4 — Apply the checklist to your mock (7 min)

Re-read the four-point PR test checklist from the lesson. In
`u2-l04-notes.md`, for each point write one clause on how your scratch's
`tests/mock_provider_test.rs` satisfies it (or what it would need to).

## Verification

```powershell
Set-Location $env:U2LABS
powershell -File <lesson-dir>\verify.ps1 -GooseRepo $env:GOOSE_REPO
```

## Homework

- Add a second canned response variant to your mock (`new` +
  `with_stream_warning`) and one test proving both variants flow through
  `complete`. Keep it under 30 lines total.
- In the clone, find one test that uses `env_lock::lock_env` (grep in
  `crates/goose/src/agents/state_machine/tests/`). Write one sentence on why
  tests lock env vars instead of just setting them.