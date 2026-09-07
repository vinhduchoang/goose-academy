# Lab 0.10 — Build a ModelConfig-shaped struct with builder-ish helpers

Timebox: 40-50 min. PowerShell 5.1, your local `goose` checkout
(`$env:GOOSE_REPO`). Scratch files in one working folder; `verify.ps1` checks
that folder plus the goose repo.

## Step 1 — Read the real ModelConfig (10 min)

Open `crates/goose-provider-types/src/model.rs` and read lines 40-60 and
102-135. In `lab10-notes.md`:

1. List the fields of `ModelConfig` and each field's type.
2. Which field is deliberately skipped by serde (`#[serde(skip)]`)? (Serde
   deep-dive is lesson 0.14 — one sentence is enough now.)
3. `new` and `with_canonical_limits`: which is an associated function, which a
   method? How can you tell from the signature alone?

## Step 2 — Your ModelConfig-shaped struct (15 min)

Create `lab10-config.rs`:

```rust
#[derive(Debug, Clone)]
pub struct AgentConfig {
    pub model_name: String,
    pub context_limit: Option<usize>,
    pub temperature: Option<f32>,
    pub streaming: bool,
}

impl AgentConfig {
    // associated fn — no self
    pub fn new(model_name: impl AsRef<str>) -> Self {
        Self {
            model_name: model_name.as_ref().to_string(),
            context_limit: None,
            temperature: None,
            streaming: true,
        }
    }

    // builder methods — consume and rebuild self
    pub fn with_context_limit(mut self, limit: usize) -> Self {
        self.context_limit = Some(limit);
        self
    }

    pub fn with_temperature(mut self, t: f32) -> Self {
        self.temperature = Some(t);
        self
    }

    pub fn disable_streaming(mut self) -> Self {
        self.streaming = false;
        self
    }

    // reads &self
    pub fn summary(&self) -> String {
        format!(
            "{} | ctx={} | temp={} | stream={}",
            self.model_name,
            match self.context_limit { Some(n) => n.to_string(), None => "default".into() },
            match self.temperature { Some(t) => t.to_string(), None => "default".into() },
            self.streaming,
        )
    }

    // parity check helper — a goose-style touch: defaults must behave
    pub fn uses_defaults(&self) -> bool {
        self.context_limit.is_none() && self.temperature.is_none()
    }
}

fn main() {
    let base = AgentConfig::new("gpt-4o");
    let tuned = AgentConfig::new("claude-sonnet-4")
        .with_context_limit(128_000)
        .with_temperature(0.3)
        .disable_streaming();

    println!("{}", base.summary());
    println!("{}", tuned.summary());
    println!("base defaults: {}", base.uses_defaults());
    println!("tuned defaults: {}", tuned.uses_defaults());

    // clone is cheap here because derive(Clone) is structural
    let copy = tuned.clone();
    println!("clone equal: {}", copy.summary() == tuned.summary());
    println!("STRUCT-OK");
}
```

Compile and run:

```powershell
rustc --edition 2021 lab10-config.rs -o lab10-config.exe
.\lab10-config.exe
```

## Step 3 — Visibility experiment (10 min)

In `lab10-notes.md` sketch (pseudocode is fine) what would change if:

1. `model_name` were private — which of `new()`, `with_*`, `summary()` still
   compile? Why?
2. `streaming` were `pub(crate)` — who could still read it? (Name the boundary
   for a goose crate.)
3. Where does the builder `mut self` pattern beat `&mut self`? (Which one
   permits `AgentConfig::new("gpt-4o").with_temperature(0.3);` chaining in one
   line?)

## Step 4 — Structs with different visibilities in goose (10 min)

Compare two real structs and note the *difference in their fields*:

1. `ModelConfig` (`model.rs:41`) — all fields `pub`.
2. `TokenCounter` (`token_counter.rs:22`) — fields private.

In `lab10-notes.md`: why does goose hide TokenCounter's fields but expose
ModelConfig's? What invariant does the private `token_cache` field protect
(hint: what machinery maintains the cache)?

## Verification

```powershell
$env:GOOSE_REPO = "C:\Users\admin\projects\goose"  # adjust to your checkout
powershell -File verify.ps1 -GooseRepo $env:GOOSE_REPO
```

Confirm `VERIFY PASSED`, then mark the lab verified in the app.

## Homework

- Add `pub fn with_max_tokens(mut self, n: i32) -> Self` to your `AgentConfig`
  parity model (ModelConfig holds `max_tokens: Option<i32>` at `model.rs:45`).
  Add the field, recompile, re-run.
- In `model.rs`, find `with_canonical_limits`'s body start (`model.rs:120`).
  One sentence in notes: what does the method *do* with `mut self` (mutate a
  field? replace self?) — and why does consuming self make that safe?