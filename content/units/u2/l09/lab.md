# Lab 2.9 — Profile a slow path; make one measurable improvement

Timebox: 40-50 min. Scratch crate + clone reading.

## Step 1 — Read the three economic files (12 min)

In the clone, read and note (in `$env:U2LABS\u2-l09-notes.md`):

1. `crates/goose/src/token_counter.rs:10-25` — what is loaded once, what is
   cached, and what the cache key is. Why is the key `(len, blake3 hash)`
   instead of the raw string?
2. `crates/goose/src/agents/large_response_handler.rs:5-11` — the threshold,
   its env override, and what the agent receives instead of the big text.
3. `crates/goose/src/config/base.rs:1326-1328` — what value of
   `GOOSE_CONTEXT_LIMIT` is treated as a config error and why.
4. Bonus: `crates/goose/src/providers/canonical_cost.rs:1-4` — the pricing
   precedence chain; one sentence on why "user's custom config" outranks the
   bundled catalog.

## Step 2 — Build the slow path and a cache (15 min)

```powershell
Set-Location $env:U2LABS
cargo new u2-l09-scratch
Set-Location u2-l09-scratch
```

Replace `src/main.rs` with a micro-benchmark of the *exact pattern* you read
in token_counter: a function that "tokenizes" (simulate with
`text.split_whitespace().count()`) and two callers:

- `naive(str)` — recomputes every call;
- `cached(&mut state, str)` — an LRU-ish memo keyed by `String` in a plain
  `HashMap` with a hard cap (1024) — evicting everything when full is fine,
  just like a bounded cache;

Harness: 5,000 calls over 20 distinct strings, using `std::time::Instant`.
Run `cargo run --release` three times, average the readings, and write the
before/after numbers into `u2-l09-profile.md`:

```
## Before (naive):    <avg ms>
## After (cached):    <avg ms>
## Input shape:       5000 calls / 20 distinct strings
## Improvement:       <factor> x
```

## Step 3 — Make one *structural* improvement (10 min)

Apply the large_response_handler lesson to your bench: add a
`spill_if_huge(&str, threshold)` in the scratch crate that, when the text
exceeds the threshold, writes it to a temp file and returns a one-line
pointer string instead (mirror the handler's contract honestly — no goose
internals). Then measure: caller-side memory of passing pointer strings vs
full texts — you only need to count characters handled, but record the
observation in `u2-l09-profile.md`:

- the threshold you chose;
- what the caller "sees" in each branch;
- how this protects context, in one sentence tying it to
  `GOOSE_MAX_TOOL_RESPONSE_SIZE`.

## Step 4 — Close the loop (8 min)

In `u2-l09-notes.md`, write the 3-bullet "Verification and performance"
section a PR author would add:

- the profile numbers (before/after),
- the one improvement shipped and which goose pattern it mirrors (once-load /
  bounded-cache / spill-to-file),
- the config keys a reviewer should know exist (`GOOSE_CONTEXT_LIMIT`,
  `GOOSE_MAX_TOOL_RESPONSE_SIZE`) with their roles in one line each.

## Verification

```powershell
Set-Location $env:U2LABS
powershell -File <lesson-dir>\verify.ps1 -GooseRepo $env:GOOSE_REPO
```

## Homework

- Read `git show 08e748051 --stat` in the clone. One paragraph: what did the
  LRU change replace, and why is "bounded" (1024) the important adjective?
- Sketch how you would profile the *real* token_counter hot path: which env
  var (from l03) would you set, and which span names would you look for in
  the logs?