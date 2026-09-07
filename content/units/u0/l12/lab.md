# Lab 0.12 — Generic `summarize<T: Display>`; implement a small trait

Timebox: 40-50 min. PowerShell 5.1, your local `goose` checkout
(`$env:GOOSE_REPO`). Scratch files in one working folder; `verify.ps1` checks
that folder plus the goose repo.

## Step 1 — Dissect the real Provider trait (15 min)

Open `crates/goose-provider-types/src/base.rs:464` and read through the trait.
In `lab12-notes.md`:

1. What supertrait bounds does `Provider` declare, and why do those two matter
   for an agent running concurrent requests?
2. Which methods have default bodies vs which is required? (Name at least
   `stream` and `complete`, and check `get_name`.)
3. What is `MessageStream` at `base.rs:327`? Write it in your own words with
   two ideas checked at compile time (the item type and the `Send` bound).

## Step 2 — Tiny trait of your own (15 min)

Create `lab12-generics.rs`:

```rust
use std::fmt::Display;

// the generic you were promised: any Display-implementing type
fn summarize<T: Display>(label: &str, items: &[T], max: usize) -> String {
    let joined: Vec<String> = items
        .iter()
        .take(max)
        .map(|i| i.to_string())
        .collect();
    format!("{}: [{}]", label, joined.join(", "))
}

// a trait with a provided method (like Provider::complete!)
trait Named {
    fn name(&self) -> &str;
    fn hello(&self) -> String {
        format!("hi, I am {}", self.name())   // default body == one method to implement
    }
}

#[derive(Debug)]
struct ProviderStub {
    id: String,
}

impl Named for ProviderStub {
    fn name(&self) -> &str {
        &self.id
    }
}

impl Display for ProviderStub {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "ProviderStub({})", self.id)
    }
}

// a generic function bounded on TWO traits: display-able AND nameable
fn introduce<T: Named + Display>(item: &T) -> String {
    format!("{}; formal display: {}", item.hello(), item)
}

fn main() {
    let nums = vec![3, 1, 4, 1, 5, 9];
    println!("{}", summarize("digits", &nums, 4));

    let names = vec!["openai", "anthropic", "test"];
    println!("{}", summarize("providers", &names, 10));

    let stub = ProviderStub { id: "test".into() };
    println!("{}", stub.hello());              // provided method
    println!("{}", introduce(&stub));           // generic fn, two bounds

    // impl Trait in argument position — ModelConfig::new pattern (model.rs:103)
    let s: String = labeled(&stub.id);
    println!("{}", s);
    println!("GENERIC-OK");
}

// newline-friendly: impl AsRef<str> accepts &str AND String
fn labeled(who: impl AsRef<str>) -> String {
    format!("stub: {}", who.as_ref())
}
```

Compile and run:

```powershell
rustc --edition 2021 lab12-generics.rs -o lab12-generics.exe
.\lab12-generics.exe
```

## Step 3 — Trait-object hunt (10 min)

Run:

```powershell
Select-String -Path "$env:GOOSE_REPO\crates\goose\src\*.rs","$env:GOOSE_REPO\crates\goose\src\agents\*.rs" -Pattern 'dyn Provider' | Select-Object -First 5 Path, LineNumber
```

In `lab12-notes.md`:

1. Where does goose hold a `dyn Provider` (look at `agents/types.rs:7` too)?
2. Why `Box<dyn>` (or `Arc<dyn>`) — what two Rust rules force the indirection?
3. Compare with TS: `Provider` interface typed variable vs `Box<dyn Provider>` —
   which property (compile-time dispatch vs runtime dispatch) do they share?

## Step 4 — Complete vs Stream (10 min)

`base.rs:485` shows `complete` defaulting to collecting `stream`. In
`lab12-notes.md`:

1. What's the exact flow (in pseudocode): stream → what → ret?
2. If a provider's streaming is expensive to buffer, what should its author do
   instead of accepting the default?
3. How does this relate to `stream_from_single_message` at `base.rs:457`
   (single-message providers wrap one message into a stream)?

## Verification

```powershell
$env:GOOSE_REPO = "C:\Users\admin\projects\goose"  # adjust to your checkout
powershell -File verify.ps1 -GooseRepo $env:GOOSE_REPO
```

Confirm `VERIFY PASSED`, then mark the lab verified in the app.

## Homework

- Grep `impl Provider for` across `crates/goose/src/providers/` and list the
  first 6 implementors you find. One line each in notes: provider name and file.
- Write `fn totals<T: AsRef<str>>(xs: &[T]) -> usize` that sums `xs[i].as_ref().len()`.
  Add it to `lab12-generics.rs`, call it, re-run.