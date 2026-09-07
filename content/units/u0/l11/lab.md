# Lab 0.11 — Parse a value chain returning Result; exhaustive match on both arms

Timebox: 40-50 min. PowerShell 5.1, your local `goose` checkout
(`$env:GOOSE_REPO`). Scratch files in one working folder; `verify.ps1` checks
that folder plus the goose repo.

## Step 1 — Read ProviderError for real (10 min)

Open `crates/goose-provider-types/src/errors.rs` and skim lines 7-61. In
`lab11-notes.md`:

1. List three variants that carry data, and the *shape* of the data
   (unit / positional `String` / named fields).
2. Which variant carries an `Option<Duration>` and what runtime policy could a
   retry loop derive from it?
3. Open `model.rs:44` — why is `context_limit` an `Option<usize>` and not just
   `usize` with 0 default?

## Step 2 — Parse a value chain (15 min)

Create `lab11-result.rs`:

```rust
#[derive(Debug, PartialEq)]
struct ModelRequest {
    name: String,
    temperature: f32,
}

// one link in the chain: parse "name:0.7" -> Result<ModelRequest, String>
fn parse_model(spec: &str) -> Result<ModelRequest, String> {
    let parts: Vec<&str> = spec.split(':').collect();
    if parts.len() != 2 {
        return Err(format!("expected 'name:temp', got '{spec}'"));
    }
    let temp: f32 = parts[1]
        .parse()
        .map_err(|e| format!("bad temperature '{}': {}", parts[1], e))?;
    Ok(ModelRequest { name: parts[0].to_string(), temperature: temp })
}

// the value chain: Result of Option, transformed, with typed errors
fn resolve_context(limit: Option<usize>) -> Result<usize, String> {
    let n = match limit {
        Some(n) => n,
        None => 128_000,   // DEFAULT_CONTEXT_LIMIT shaped fallback (model.rs:11)
    };
    if n < 1_024 { Err(format!("limit {n} too small")) } else { Ok(n) }
}

fn main() {
    let specs = vec!["gpt-4o:0.7", "claude:not-a-float", "missing-colon"];
    for s in specs {
        match parse_model(s) {
            Ok(req) => println!("{} -> {:?}", s, req),
            Err(e) => println!("{} -> ERROR: {}", s, e),
        }
    }

    // Option chain: map converts only the Some case
    let maybe = Some(256_000usize);
    let in_k = maybe.map(|n| n / 1_024);
    println!("256000 tokens = {:?}k", in_k);

    // exhaustive match on both arms of Result, then of Option
    for limit in [Some(512usize), None, Some(128_000usize)] {
        match resolve_context(limit) {
            Ok(n) => println!("context: {}", n),
            Err(e) => println!("context: ERROR {}", e),
        }
    }
    println!("RESULT-OK");
}
```

Compile and run:

```powershell
rustc --edition 2021 lab11-result.rs -o lab11-result.exe
.\lab11-result.exe
```

## Step 3 — Delete an arm, meet the teacher again (10 min)

1. Comment out the `None =>` arm in `resolve_context` and compile. Record the
   error code in `lab11-notes.md`.
2. Restore it. Now change `resolve_context`'s signature to return
   `Result<usize, String>` and replace the body with
   `Ok(limit.ok_or("no limit configured")?)` — does the `?` behave like the
   match you removed? Write the rule of thumb in notes ("? = match { Ok(v) => v, Err(e) => return Err(e) }" — but `?` also converts error types; the full version is lesson 0.13).

## Step 4 — Real-world Result handling in goose (10 min)

Open `crates/goose-provider-types/src/base.rs:485-494` — `complete()` builds on
`stream()`:

In `lab11-notes.md`:

1. What are `complete`'s two return arms in practice (the `.await?` and the
   final expression)?
2. `collect_stream` (same file, around line 440) returns `Result<(Message,
   usage), ProviderError>` — find its signature and write down what `Ok` and
   `Err` carry.
3. Why is "error as value" the right model for a streaming provider — what
   would a TS `throw` across 15 concurrent streams cost you that the enum
   doesn't?

## Verification

```powershell
$env:GOOSE_REPO = "C:\Users\admin\projects\goose"  # adjust to your checkout
powershell -File verify.ps1 -GooseRepo $env:GOOSE_REPO
```

Confirm `VERIFY PASSED`, then mark the lab verified in the app.

## Homework

- Add a `Refusal`-style variant to a *your-own* enum in `lab11-result.rs`:
  `enum Gate { Open, Refused { reason: String } }`, match it exhaustively, print
  both arms. Recompile, re-run.
- In `errors.rs`, find `telemetry_type`'s `match self` (around `errors.rs:68`).
  One sentence: what does this function prove about how goose *categorizes*
  provider failures for observability?