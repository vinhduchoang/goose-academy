# Lab 0.1 — Build goose and map the workspace

Timebox: 40-50 min. Do everything in PowerShell 5.1 against your local
`goose` checkout (`$env:GOOSE_REPO`, defaults to `C:\Users\admin\projects\goose`).

## Step 1 — Confirm the toolchain (5 min)

Run each of these and paste the first output line into a scratch note:

```powershell
rustup --version
cargo --version
rustc --version
```

Expected: a `rustup` line, a `cargo` line matching the rustc family
(1.96.x — the `rust-toolchain.toml` pin for goose v1.49.0), and `rustc` itself.

## Step 2 — Build goose (10-25 min, coffee time)

```powershell
Set-Location $env:GOOSE_REPO
cargo build -p goose-cli --bin goose
```

If clippy/rustc complaints appear about *your* machine: it's not your code yet —
read the last 5 lines before the error to learn how rustc errors are structured
(note the `--> file:line:col` arrow).

<FounderLens>

`cargo build` here pulls several hundred crates. The `Cargo.lock` file makes that
whole graph reproducible — commit it, never hand-edit it. Goose vendors its lock
for a reason: contributors must compile the exact same graph CI does.

</FounderLens>

## Step 3 — Map every crate (15 min)

```powershell
cargo metadata --no-deps --format-version 1 | ConvertFrom-Json | ForEach-Object {
  $_.packages | Select-Object name, version | Format-Table
}
```

For each crate print one sentence into `lab01-notes.md`:

- what it builds (lib / bin / both / proc-macro)
- one workspace-local dependency it has (from `dependencies` in its `Cargo.toml`)

Then answer: which crate depends on *no* other workspace crate? Which is depended
on by the most crates? (Hint: the answer will come back in Unit 1 — write a guess
now.)

## Step 4 — The Justfile (10 min)

Open the root `Justfile` at `Justfile:7`. `check-everything` is the gate
maintainers run before a PR. Read it and identify, in your notes:

1. What does `cargo clippy --all-targets -- -D warnings` do differently from plain
   `cargo clippy`?
2. Why does the recipe also lint `ui/desktop` instead of stopping at Rust?

## Verification

Run the lab's check script and make sure it prints `VERIFY PASSED`:

```powershell
$env:GOOSE_REPO = "C:\Users\admin\projects\goose"  # adjust to your checkout
powershell -File verify.ps1 -GooseRepo $env:GOOSE_REPO
```

Then mark this lab as verified in the app (Lab tab → checkbox).

## Homework

- Run `cargo fmt --all -- --check` **before** touching any file — for now just
  confirm it passes on a clean tree.
- Skim `rust-toolchain.toml` at the repo root. One sentence in your notes: what
  exact toolchain channel does goose pin?