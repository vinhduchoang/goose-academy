# Lab 0.9 — Grep lifetimes in goose; write 2 functions needing explicit annotations

Timebox: 40-50 min. PowerShell 5.1, your local `goose` checkout
(`$env:GOOSE_REPO`). Scratch files in one working folder; `verify.ps1` checks
that folder plus the goose repo.

## Step 1 — Lifetime census in real goose (10 min)

Run this in PowerShell:

```powershell
Select-String -Path "$env:GOOSE_REPO\crates\goose\src\*.rs","$env:GOOSE_REPO\crates\goose\src\**\*.rs" -Pattern "'a" | Select-Object -First 12 Path, LineNumber
```

(The `**` form needs PowerShell to expand recursively; if nothing shows for it,
pick three files from the lesson cites and grep those.)

In `lab09-notes.md` record at least three distinct lifetime usages, each as:
`file:line`, the construct kind (struct / fn / impl), and one sentence on what
the lifetime relates.

Hit parade if you get stuck: `logging.rs:13` (LoggingConfig), `checks/mod.rs:162`
(resolved_model), `prompt_manager.rs:45` (SystemPromptBuilder).

## Step 2 — Two functions that need explicit lifetimes (15 min)

Create `lab09-lifetimes.rs`:

```rust
// 1. Two input refs, one output — compiler can't guess which input it comes from.
//    Without the annotation this is E0106.
fn longer_of<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() { x } else { y }
}

// 2. A borrow-storing struct, shaped like goose's LoggingConfig<'a>
struct PromptView<'a> {
    label: &'a str,
    body: &'a str,
}

impl<'a> PromptView<'a> {
    fn render(&self) -> String {
        format!("[{}] {}", self.label, self.body)
    }
}

fn main() {
    let sys = String::from("You are a helpful coding agent.");
    let compact = String::from("Be terse.");

    println!("longer: {}", longer_of(&sys, &compact));

    let view = PromptView { label: "system", body: &sys };
    println!("{}", view.render());

    // 'static data: literals live forever, so a &'static str works here
    let tag: &'static str = "goose-v1.49";
    println!("tag: {}", tag);
    println!("LIFETIME-OK");
}
```

Compile and run:

```powershell
rustc --edition 2021 lab09-lifetimes.rs -o lab09-lifetimes.exe
.\lab09-lifetimes.exe
```

## Step 3 — The E0106 experiment (10 min)

Remove `<'a>` and the two `&'a` annotations from `longer_of` so it reads:

```rust
fn longer_of(x: &str, y: &str) -> &str {
```

Compile and save the error block into `lab09-notes.md`. Answer:

1. What error code appears (E0106)?
2. What does the error's "help" paragraph offer as the fix — does it match the
   annotation you re-add?
3. Why is the elision rule (one input) not enough when there are two inputs and
   one output?

Then restore and re-run.

## Step 4 — Explain a real lifetime signature (10 min)

Open `crates/goose/src/checks/mod.rs:162` (`resolved_model`). In `lab09-notes.md`:

1. List the parameters and the return type. How many share `'a`?
2. Why does the *body* probably prefer `override_model`, else `default_model`,
   else something on `self` — and why does tying them all to `'a` keep that safe?
3. Read a few lines after `resolved_model` — does the function's logic appear
   to return a value owned by the caller, or a view into the inputs? (No need to
   trace fully — describe the type's promise.)

## Verification

```powershell
$env:GOOSE_REPO = "C:\Users\admin\projects\goose"  # adjust to your checkout
powershell -File verify.ps1 -GooseRepo $env:GOOSE_REPO
```

Confirm `VERIFY PASSED`, then mark the lab verified in the app.

## Homework

- `LoggingConfig<'a>` at `logging.rs:13` — find one place goose *builds* a
  `LoggingConfig` (search `LoggingConfig {`). State in notes what it borrows and
  why the borrow outlives the config.
- Write in notes: which is wrong — "lifetimes make values live longer" or
  "lifetimes describe which borrows may outlive which"? Why?