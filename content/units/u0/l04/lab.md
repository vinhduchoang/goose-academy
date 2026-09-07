# Lab 0.4 — Port a TS helper to idiomatic Rust functions

Timebox: 40-50 min. PowerShell 5.1, your local `goose` checkout
(`$env:GOOSE_REPO`). Scratch files in one working folder; `verify.ps1` checks
that folder plus the goose repo.

## Step 1 — Read two real function bodies (10 min)

Open these in your editor and read only the function bodies:

1. `crates/goose-provider-types/src/base.rs:457` — `stream_from_single_message`
2. `crates/goose/src/token_counter.rs:53` — `count_tokens`

In `lab04-notes.md`:

- Which one returns via last-expression, and which uses an early `return`?
- What parameter kinds do you see (`&self`, `&str`, owned values)?

## Step 2 — Port the TS helper (20 min)

Here is a TS helper goose-adjacent engineers write in chat UIs all the time:

```typescript
// truncates a model reply to maxChars, but never cuts a multi-byte char in half;
// if there is room, it puts an ellipsis on the end
function charTruncate(s: string, maxChars: number): string {
  const chars = Array.from(s); // code points, not UTF-16 units
  if (chars.length <= maxChars) return s;
  return chars.slice(0, maxChars - 1).join("") + "…";
}
```

Port it to idiomatic Rust in `lab04-fns.rs`:

```rust
fn char_truncate(s: &str, max_chars: usize) -> String {
    let count = s.chars().count();
    if count <= max_chars {
        return s.to_string();
    }
    let head: String = s.chars().take(max_chars - 1).collect();
    head + "…"   // last expression IS the return value
}

// block-as-value used for tests
fn check(label: &str, got: &str, want: &str) {
    let ok = got == want;
    println!("{} {}/{} {}", if ok { "PASS" } else { "FAIL" }, label, got, want);
}

fn main() {
    let full = "Model replies with a very long sentence.";
    check("no-op       ", &char_truncate(full, 100), full);
    check("ellipsis    ", &char_truncate(full, 12), "Model repli…");
    // Unicode: each char is one code point
    check("unicode     ", &char_truncate("héllo wörld", 6), "héllo …");
    check("exact       ", &char_truncate("abcdef", 6), "abcdef");
    println!("FNS-OK");
}
```

Compile and run:

```powershell
rustc --edition 2021 lab04-fns.rs -o lab04-fns.exe
.\lab04-fns.exe
```

All four lines must start with `PASS`.

## Step 3 — Add a built-by-expression function (10 min)

Append to `lab04-fns.rs` (and call it from `main` before the `FNS-OK` print):

```rust
// one expression, block-scoped helper, no return keyword anywhere
fn status_line(model: &str, tokens: usize) -> String {
    let tag = {
        if tokens > 100_000 { "big" } else { "small" }
    };
    format!("{model} [{tag}, {tokens} tokens]")
}
```

Call `status_line("gpt-4o", 128_000)` and print the result. Note in
`lab04-notes.md`: how many `return` keywords did you write in the whole file?

## Step 4 — Functions in goose: hunt (10 min)

In `crates/goose/src/token_counter.rs` find one function whose return type is
NOT `usize`, and note its signature in `lab04-notes.md`. Then check your
understanding: which of these must be true for every Rust fn?

- Every parameter is typed.
- The return type may be omitted only when it's `()` (unit).
- Function bodies end with an expression unless there's an explicit `return`.

(Fix any of the three that are wrong, citing reality from `token_counter.rs:53`.)

## Verification

```powershell
$env:GOOSE_REPO = "C:\Users\admin\projects\goose"  # adjust to your checkout
powershell -File verify.ps1 -GooseRepo $env:GOOSE_REPO
```

Confirm `VERIFY PASSED`, then mark the lab verified in the app.

## Homework

- Skim `base.rs:457` again. Why does it return `Box::pin(stream)` rather than
  `stream` itself? One sentence in your notes.
- Write (mentally or in notes) the TS-to-Rust mapping table: IIFE ↔ block-as-value,
  `Array.from(s)` ↔ `s.chars()`, `slice().join("")` ↔ `take().collect()`.