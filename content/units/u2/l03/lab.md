# Lab 2.3 — Debug a failing integration test to root cause

Timebox: 40-50 min. Works in `$env:U2LABS`. One tiny scratch crate (compiles
in seconds — not the goose build).

## Step 1 — Read goose's filter wiring (8 min)

Open `crates/goose/src/logging.rs` in the clone. From `build_env_filter`
(`logging.rs:30-46`) answer in notes:

1. What is the exact default directive list?
2. What happens to your `RUST_LOG` when it contains an invalid directive like
   `goose=definitely-not-a-level`? (Read `build_env_filter` itself — the invalid
   value is discarded and the defaults apply. Contrast, optional: the OTel
   exporter at `otel/otlp.rs:565` falls back to `OTEL_LOG_LEVEL` instead.)

Start `u2-l03-notes.md` in `$env:U2LABS` with these two answers.

## Step 2 — Spans find the root cause (15 min)

Create the scratch crate:

```powershell
Set-Location $env:U2LABS
cargo new u2-l03-scratch
Set-Location u2-l03-scratch
cargo add tracing tracing-subscriber  # tiny; seconds to compile
```

Replace `src/main.rs` with: an `AppError` enum, a `build_label(parts: &[&str])`
function that **panics when the joined label exceeds 80 chars**, and a
`run()` that calls `build_label` with a 3-segment input that overflows. No
`#[instrument]` anywhere yet. Make `main` install the subscriber with an env
filter, so `RUST_LOG` actually reaches it:

```rust
tracing_subscriber::fmt()
    .with_env_filter(tracing_subscriber::EnvFilter::try_from_default_env().unwrap_or_default())
    .init();
```

Run `cargo run` — you get a panic with a line number only.

Now instrument: add `#[instrument(level = "debug")]` to `build_label` and
`#[instrument(name = "app_run")]` to `run`. Run these three ways and record
which lines appear in each:

```powershell
cargo run
$env:RUST_LOG = "u2_l03_scratch=debug"; cargo run
$env:RUST_LOG = "u2_l03_scratch=trace"; cargo run
```

Write into `u2-l03-notes.md`:

- the root cause in one sentence (which segment pushed the length past 80);
- why run #1 printed nothing (bind it to RUST_LOG defaults);
- the exact span names you saw.

## Step 3 — Snapshots: when to use them, how to update them (10 min)

In the clone, open `crates/goose/src/agents/prompt_manager.rs:479` and look at
the `.snap` files in `crates/goose/src/agents/snapshots/`. Then answer in
notes:

1. What is stored in `goose__agents__prompt_manager__tests__basic.snap`
   (first 10 lines sufficient)?
2. If someone changes the default system prompt, which two legitimate update
   paths exist (hint: `cargo insta` tooling vs `INSTA_UPDATE` env var)? Why
   does `.gitignore` mention `*.snap.new`?

## Step 4 — Threads: prove shared state is racy (12 min)

In the scratch crate, add one integration test file `tests/racy.rs` with two
tests that both read-modify-write a `static COUNTER: AtomicUsize` (increment,
then assert the observed value equals the increment count). Run it three ways:

```powershell
cargo test --test racy
cargo test --test racy -- --test-threads=1
cargo test --test racy -- --test-threads=8
```

Record in notes: which runs passed/failed, and why goose CI does the same
dance for scenario tests (read `.github/workflows/ci.yml:74-75` first). Name
one fix that preserves parallelism instead of serializing tests.

## Verification

```powershell
Set-Location $env:U2LABS
powershell -File <lesson-dir>\verify.ps1 -GooseRepo $env:GOOSE_REPO
```

## Homework

- Set `$env:RUST_LOG = "mcp_client=trace"` and run **one** existing goose test
  of your choice with `-- --nocapture` (e.g.
  `cargo test -p goose --test mcp_integration_test -- --nocapture` if your
  build machine allows). Paste 3 interesting log lines into a scratch note
  with what each told you.
- Find one `tracing::warn!` / `debug_span!` site in `crates/goose/src` and
  write the RUST_LOG directive that would surface it.