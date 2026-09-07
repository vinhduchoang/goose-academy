# Lab 0.2 — Token-count exercise, inferred vs explicit types

Timebox: 40-50 min. Do everything in PowerShell 5.1 against your local
`goose` checkout (`$env:GOOSE_REPO`, defaults to `C:\Users\admin\projects\goose`).
Work in one scratch folder (anywhere); `verify.ps1` checks that folder plus the
goose repo.

## Step 1 — Read the token constants (5 min)

Open `crates/goose/src/token_counter.rs` in your editor. In the top section find
the `const` block (`token_counter.rs:12` through `:20`). Write into
`lab02-notes.md`:

- the name, type, and value of each constant
- which constant is an `isize` and why it must be signed (hint: it can be
  *subtracted* from a running total)

## Step 2 — Type hunt: inferred vs explicit (10 min)

In the same file, classify these bindings: inferred or annotated? (Only look at
the declaration line.)

1. `MAX_TOKEN_CACHE_SIZE` at `token_counter.rs:12`
2. `func_token_count` at `token_counter.rs:76`
3. the return type of `count_tokens` at `token_counter.rs:53`
4. `cache_capacity` right after `NonZeroUsize::new(...)` at `token_counter.rs:46`

For each, note in `lab02-notes.md` what the final type is and whether the
annotation was written or inferred by you/us.

## Step 3 — Write the token-budget exercise (15 min)

Create `lab02-tokens.rs` (plain file — single-file Rust needs no cargo project):

```rust
fn fits_in_budget(limit: usize, tokens: usize) -> bool {
    tokens <= limit
}

fn main() {
    let context_limit: usize = 128_000;
    let prompt_tokens = 3_412usize;
    let history_tokens = dbg!(prompt_tokens * 4);          // inferred
    let total = prompt_tokens + history_tokens;

    let verdict = fits_in_budget(context_limit, total);     // call the fn
    // shadowing: a new binding with the same name may change type!
    let verdict = if verdict { "fits" } else { "over budget" };
    println!("{}: {} tokens of {} -> {}", verdict, total, context_limit, verdict);

    let temperature: f32 = 0.7;
    let mut temperature = temperature;   // now mutable via shadowing
    temperature *= 10.0;
    println!("temp x10 = {}", temperature);
    if fits_in_budget(context_limit, total) {
        println!("BUDGET-OK");
    }
}
```

Compile and run:

```powershell
rustc --edition 2021 lab02-tokens.rs -o lab02.exe
.\lab02.exe
```

Paste the `dbg!` output line into `lab02-notes.md` — note the `file:line` format
rustc gives you for free.

## Step 4 — Spot the inference mistake (10 min)

Which of these statements is true? Pick one, and justify in `lab02-notes.md`:

- `let x = 40;` is `i32` because integer literals default to `i32`.
- `let x = 40;` is `usize` because sizes are always `usize`.
- `let x = 40usize;` and then `x *= 2.5;` compiles, because `usize` is just a number.

(Hint: try compiling the third one — that error message is your study guide.)

## Verification

Run the lab's check script:

```powershell
$env:GOOSE_REPO = "C:\Users\admin\projects\goose"  # adjust to your checkout
powershell -File verify.ps1 -GooseRepo $env:GOOSE_REPO
```

Make sure it prints `VERIFY PASSED`, then mark the lab verified in the app.

## Homework

- In `crates/goose/src/token_counter.rs`, find the line where a `Mutex<...>`
  guard wraps the token cache. One sentence in your notes: which primitive types
  do you see *inside* the generic brackets?
- Add to `lab02-notes.md`: why do you think goose stores token counts as `usize`
  rather than `u64`? (Think about cache sizes, indexing, and string lengths.)