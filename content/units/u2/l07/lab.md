# Lab 2.7 — Ship a tiny feature through the full mini-cycle

Timebox: 40-50 min. Scratch crate + one scratch recipe; clone for reading the
real self-test file.

The feature: **`fit_label(text, max_chars)`** — a UTF-8-safe label fitter:
truncate on a char boundary at `max_chars`, append nothing if it already
fits, return the string unchanged otherwise. (This is the *right* version of
the bug you traced in l06.)

## Step 1 — Proposal, template form (10 min)

Write `$env:U2LABS\u2-l07-proposal.md` mirroring
`.github/ISSUE_TEMPLATE/feature_request.md`:

- **What problem would this solve?** (tool labels panicking/corrupting on
  multibyte input — connect to your l06 findings)
- **What would a good outcome look like?** (observable: no panic, label
  length in chars never exceeds max, identical bytes preserved when fitting)
- **Possible approaches** (chars().take() vs get(..) + fallback — one line
  each with a tradeoff)
- **Scope line** (one subsystem, no config knobs)

## Step 2 — Minimal impl + tests (15 min)

```powershell
Set-Location $env:U2LABS
cargo new --lib u2-l07-scratch
Set-Location u2-l07-scratch
```

In `src/lib.rs`:

```rust
pub fn fit_label(text: &str, max_chars: usize) -> String {
    if text.chars().count() <= max_chars {
        text.to_string()
    } else {
        text.chars().take(max_chars).collect()
    }
}
```

In `tests/fit_label_test.rs`, assert the outcome (not the implementation):
exact-fit preserved, long ASCII truncated at boundary, multibyte "José…" with
max cutting mid-char stays valid UTF-8 (byte-length may exceed max — that's
fine and correct; assert it does NOT panic and that `chars().count()` equals
max). Run `cargo test` — green.

## Step 3 — Update the self-test recipe (12 min)

Read the real file in the clone:

```powershell
Get-Content $env:GOOSE_REPO\goose-self-test.yaml -TotalCount 40
```

Note its skeleton: `version`, `title`, `activities`, `parameters`,
`instructions`, `extensions`, `prompt`. Now create
`$env:U2LABS\u2-l07-selftest.yaml` — a mini recipe with the same skeleton
(minified) that adds ONE scenario: "Validate UTF-8-safe label fitting" —
in its activities list, and in its prompt a small block telling a future
goose: call the function's host binary with a multibyte label, observe no
panic, record the result to a log file.

Then write `u2-l07-selftest-plan.md`:

1. Which phase of the REAL `goose-self-test.yaml` would your scenario live
   in (look at the phase names in the prompt: basic, extensions, delegation,
   advanced...)? Justify in one sentence.
2. Where does AGENTS.md:94 say this validation must be run, and with which
   exact command?
3. Why does the rule say "rebuild" before the recipe run?

## Step 4 — Rehearse the run command (8 min)

You may not have a configured provider to actually run goose end-to-end —
that's fine; rehearse precisely:

```powershell
Set-Location $env:GOOSE_REPO
cargo build -p goose-cli --bin goose   # optional if already built
goose run --recipe goose-self-test.yaml --help   # confirm flag exists
```

Record in `u2-l07-selftest-plan.md` the exact command a CI-green PR of yours
would cite in its verification plan, including path and flags.

## Verification

```powershell
Set-Location $env:U2LABS
powershell -File <lesson-dir>\verify.ps1 -GooseRepo $env:GOOSE_REPO
```

## Homework

- Open `workflow_recipes/release_risk_check/recipe.yaml` fully. List its
  `parameters` keys and write one sentence mapping each to the recipe's
  `{{...}}` template placeholders.
- Draft the **PR description** for your fit_label feature: issue link line,
  implementation one-paragraph, tests run, self-test update, verification
  plan — 10 lines max.