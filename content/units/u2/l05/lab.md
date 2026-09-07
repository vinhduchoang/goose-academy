# Lab 2.5 — Land 3 warning fixes; get clippy green with -D warnings

Timebox: 40-50 min. Scratch crate under `$env:U2LABS`; the real clone for
policy reading only.

## Step 1 — Read the workspace policy (8 min)

In the clone, open the root `Cargo.toml` at the `[workspace.lints.clippy]`
section (line 18). Record in notes:

1. The exact lint names the workspace overrides, and their levels.
2. Why `string_slice` is warn while `uninlined_format_args` is allow — one
   sentence each, in your own words (correctness vs style churn).
3. What `Justfile:13` (`--all-targets -- -D warnings`) would do to a warn
   lint at the gate.

Save as `$env:U2LABS\u2-l05-notes.md`.

## Step 2 — Plant the warnings, then capture them (7 min)

```powershell
Set-Location $env:U2LABS
cargo new u2-l05-scratch
Set-Location u2-l05-scratch
```

Replace `src/main.rs` with a small program that plants one of each class:

```rust
fn main() {
    let full_name = "José Mouse";          // non-ASCII on purpose
    let is_dirty = true;
    let cached: u64 = 7;

    let initials = &full_name[0..2];        // string_slice candidate
    if is_dirty == true {                   // needless comparison
        println!("{}", initials);
    }
    let label = cached.clone();             // redundant clone of Copy
    println!("{}", label);
}
```

Run `cargo clippy` (scaffold builds in seconds). Copy the three lint names it
emits into `u2-l05-notes.md` — if your toolchain prints fewer than three,
note which ones did NOT fire and research why (e.g. the lint's default level
in your clippy version).

## Step 3 — Fix each warning at the source (15 min)

Hand-fix each site (no `--fix`):

1. `string_slice` -> `.get(0..2)` with a deliberate fallback. Decide and
   document: `unwrap_or` with what placeholder, and *why* (what would a
   "??"-style default do to downstream code — is silent default acceptable
   here or should it be an explicit error?).
2. `is_dirty == true` -> bare boolean.
3. `cached.clone()` -> copy semantics.

The program must still compile and print the same thing as the *intended*
behavior (watch the non-ASCII case: what does the original actually print for
"José"?).

## Step 4 — The gate run (10 min)

```powershell
cargo fmt
cargo clippy --all-targets -- -D warnings
```

Expected: zero warnings, exit 0. Then answer in `u2-l05-notes.md`:

- Would `cargo clippy --fix` have been safe for fix #1? What does the
  auto-fix risk changing semantically, and how would a reviewer catch it?
- Which of your three fixes changes observable behavior, and which is purely
  mechanical? Why does that distinction decide whether your PR is "Small" or
  needs tests added?

## Verification

```powershell
Set-Location $env:U2LABS
powershell -File <lesson-dir>\verify.ps1 -GooseRepo $env:GOOSE_REPO
```

## Homework

- Grep the clone for existing `#[allow(...)]` attributes in
  `crates/goose/src` (`Select-String -Pattern "#\[allow\(" `). Pick one, read
  its context, and write one sentence on whether you judge it justified.
- Introduce one *new* planted warning class of your choice in the scratch
  crate (e.g. `unwrap` on transport code as a stand-in for a goose-style
  `anyhow` migration) and fix it — log both in a homework note.