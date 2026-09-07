# Lab 0.6 — Match on a goose-shaped enum; let the compiler teach exhaustiveness

Timebox: 40-50 min. PowerShell 5.1, your local `goose` checkout
(`$env:GOOSE_REPO`). Scratch files in one working folder; `verify.ps1` checks
that folder plus the goose repo.

## Step 1 — Read two real enums (10 min)

1. `crates/goose/src/agents/retry.rs:23` — `RetryResult` (four variants, one
   carries a `Message`)
2. `crates/goose/src/agents/types.rs:61` — `SuccessCheck` (one variant today)

In `lab06-notes.md`:

- List each `RetryResult` variant and whether it carries data.
- Why do you think `SuccessCheck` only has one variant? (Hint: read the serde
  attribute above it and the comment about future-proofing in the lesson.)

## Step 2 — Your enum + exhaustive match (15 min)

Create `lab06-match.rs`:

```rust
#[derive(Debug)]
enum Command {
    Say(String),
    Toast { message: String, seconds: u32 },
    Retry(u32),
    Quit,
}

fn describe(cmd: &Command) -> String {
    match cmd {
        Command::Say(text) => format!("say \"{}\"", text),
        Command::Toast { message, seconds } => {
            format!("toast \"{message}\" for {seconds}s")
        }
        Command::Retry(n) => format!("retry x{}", n),
        Command::Quit => "quit".to_string(),
    }
}

fn is_important(cmd: &Command) -> bool {
    if let Command::Toast { seconds, .. } = cmd {
        *seconds >= 5
    } else {
        false
    }
}

fn main() {
    let cmds = vec![
        Command::Say("hello".into()),
        Command::Toast { message: "rebuild done".into(), seconds: 8 },
        Command::Retry(3),
        Command::Quit,
    ];
    for c in &cmds {
        println!("{:?} -> {}", c, describe(c));
    }
    println!("important toasts: {}",
        cmds.iter().filter(|c| is_important(c)).count());

    // binding in patterns: capture the payload of the first Say
    for c in &cmds {
        if let Command::Say(text) = c {
            println!("first say: {}", text);
            break;
        }
    }
    println!("MATCH-OK");
}
```

Compile and run:

```powershell
rustc --edition 2021 lab06-match.rs -o lab06-match.exe
.\lab06-match.exe
```

## Step 3 — Meet the exhaustiveness teacher (10 min)

Comment out the `Command::Quit => ...` arm (Rust comments: `//`), recompile, and
capture the error into `lab06-notes.md`. Answer:

1. What error code does non-exhaustive match produce (E0004 / E0005)?
2. Which variants does rustc say are not covered?
3. Bonus: add `#[non_exhaustive]` above your `Command` enum and think — where in
   goose would that attribute matter for an enum that extension authors match
   on?

Then restore the arm and confirm `MATCH-OK` again.

## Step 4 — Destructure like testprovider.rs (10 min)

Open `crates/goose/src/providers/testprovider.rs:91`. In `lab06-notes.md`
describe, in your own words, what each of these pieces does in that real match:

- `ref mut req`
- `ref mut result @ CallToolResult { .. }`
- the final `_ => {}` arm

Then write (in `lab06-match.rs`, above `main`) a tiny helper that *guards* a
pattern:

```rust
fn needs_attention(cmd: &Command) -> bool {
    // two guarded arms are cleaner than one guard inside an or-pattern
    matches!(cmd, Command::Retry(n) if *n > 1)
        || matches!(cmd, Command::Toast { seconds, .. } if *seconds >= 4)
}
```

(If this errors, fix and re-run. Note in your notes what `matches!` does.)

## Verification

```powershell
$env:GOOSE_REPO = "C:\Users\admin\projects\goose"  # adjust to your checkout
powershell -File verify.ps1 -GooseRepo $env:GOOSE_REPO
```

Confirm `VERIFY PASSED`, then mark the lab verified in the app.

## Homework

- Open `crates/goose-provider-types/src/errors.rs` and skim `telemetry_type`
  (a `match self` over `ProviderError`). One sentence: what strings does it
  map `RateLimitExceeded` and `NotConfigured` to, and would this function
  compile if a `ProviderError` variant were added? (Why not?)
- In your notes: translate `describe()` above into TS `switch`, and list one
  bug class your TS version permits that the Rust one does not.