# Lab 0.8 — Write `trim_prompt(&str) -> &str`; borrow-checker drills

Timebox: 40-50 min. PowerShell 5.1, your local `goose` checkout
(`$env:GOOSE_REPO`). Scratch files in one working folder; `verify.ps1` checks
that folder plus the goose repo.

## Step 1 — Read real borrow signatures (10 min)

Open these and record the signatures in `lab08-notes.md`:

1. `crates/goose/src/token_counter.rs:53` — `count_tokens(&self, text: &str) -> usize`
2. `crates/goose/src/providers/testprovider.rs:78` — `hash_input(messages: &[Message]) -> String`
3. `crates/goose/src/providers/testprovider.rs:90` — `for content in &mut cleaned_content`

For each: shared or mutable? Does the return value *depend on* the borrow (i.e.
borrowed from the input) or is it owned?

## Step 2 — trim_prompt and friends (15 min)

Create `lab08-borrow.rs`:

```rust
fn trim_prompt(prompt: &str) -> &str {
    prompt.trim()
}

fn first_word(prompt: &str) -> &str {
    match prompt.split_whitespace().next() {
        Some(w) => w,
        None => "",
    }
}

fn append_marker(s: &mut String) {
    s.push_str(" [trimmed]");
}

fn main() {
    let prompt = String::from("   You are a helpful coding agent.   ");
    let trimmed: &str = trim_prompt(&prompt);
    println!("trimmed: {:?}", trimmed);
    println!("first word: {:?}", first_word(&prompt));

    // prompt is still alive and owned here — the borrows above are over
    let mut p2 = prompt.clone();
    append_marker(&mut p2);
    println!("{}", p2);

    // slice borrow: a view, owner untouched
    let view: &str = &prompt[..10];
    println!("view: {:?}", view);

    println!("BORROW-OK");
}
```

Compile and run:

```powershell
rustc --edition 2021 lab08-borrow.rs -o lab08-borrow.exe
.\lab08-borrow.exe
```

## Step 3 — Break it three ways (15 min)

In `lab08-broken.md` (or notes) record each error code and the `-->` line the
compiler points at for these three drills — one at a time, then revert:

1. **E0502 drill** — change `let prompt` to `let mut prompt`, then after
   `let view = &prompt[..10];` add `prompt.clear();` while `view` is still used
   below — the mutation while borrowed.
2. **E0515 drill** — write

   ```rust
   fn broken_trim() -> &str {
       let s = String::from("x");
       s.trim()   // returning a borrow of a dropped local
   }
   ```

3. **E0502 drill** — in a tiny `fn two_borrows()`: take `let mut map = vec![1];`
   then `let r = &mut map[0];` then `let len = map.len();` (read while a mutable
   borrow is live).

For each, one sentence in `lab08-notes.md`: what rule did you violate?

## Step 4 — The slice-returning function in the wild (10 min)

Goose returns borrows from inputs routinely. Find ONE example where a goose
function returns `-> &str` or `-> &'a str` (search `checks/mod.rs:162` for
`resolved_model` if you want a hint), then in `lab08-notes.md`:

1. Name the function and its input parameters.
2. Explain why the returned value can safely borrow the input (what guarantees
   does the caller get).

## Verification

```powershell
$env:GOOSE_REPO = "C:\Users\admin\projects\goose"  # adjust to your checkout
powershell -File verify.ps1 -GooseRepo $env:GOOSE_REPO
```

Confirm `VERIFY PASSED`, then mark the lab verified in the app.

## Homework

- Write `fn without_prefix<'s>(text: &'s str, prefix: &str) -> &'s str` that
  strips `prefix` when present using `strip_prefix().unwrap_or(text)`. Compile
  it in `lab08-borrow.rs`. (Sounds like lifetimes — that's exactly lesson 0.9's
  topic; keep your solution.)
- Add to notes: why can `trim_prompt` return `prompt.trim()` without any
  lifetime annotation written by hand? What is that called? (Hint: elision.)