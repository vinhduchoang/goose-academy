# Lab 0.13 — Refactor panic/unwrap into `?` with typed results; compare with goose style

Timebox: 40-50 min. PowerShell 5.1, your local `goose` checkout
(`$env:GOOSE_REPO`). Scratch files in one working folder; `verify.ps1` checks
that folder plus the goose repo.

## Step 1 — Read goose's error styles (10 min)

Open:

1. `crates/goose-provider-types/src/errors.rs` — the thiserror enum (lines 3-9
   and 94)
2. `crates/goose/src/providers/testprovider.rs` — the anyhow style (lines 1,
   125, 163)
3. `crates/goose/Cargo.toml:97-98` — the two deps side by side.

In `lab13-notes.md`:

- Why is `errors.rs` (a *library* crate) using thiserror, while `testprovider.rs`
  (inside the goose *app*) uses anyhow?
- What does `?` do in one sentence, referencing `testprovider.rs:125`?

## Step 2 — Build the panic-y version (10 min)

Create `lab13-errors.rs` **starting from this seeded bad style**:

```rust
use std::fs;

// SEEDED BAD STYLE: unwrap + panic everywhere (this is today's starting point)
fn read_model_config(path: &str) -> String {
    let raw = fs::read_to_string(path).unwrap();
    let line = raw.lines().next().unwrap();
    let mut parts = line.split(':');
    let name = parts.next().unwrap();
    let temp: f32 = parts.next().unwrap().parse().unwrap();
    format!("{} @ {}", name, temp)
}

fn main() {
    let ok = read_model_config("config.txt");
    println!("{}", ok);
    let _boom = read_model_config("missing.txt");
    println!("ERR-MARKER-UNREACHED");
}
```

Create `config.txt` next to it (PowerShell):

```powershell
Set-Content -Path config.txt -Value "gpt-4o:0.7"
```

Run it and watch it panic on `missing.txt`:

```powershell
rustc --edition 2021 lab13-errors.rs -o lab13-errors.exe
.\lab13-errors.exe
```

Copy the panic message into `lab13-notes.md`.

## Step 3 — Refactor to typed Results + `?` (20 min)

Rewrite `lab13-errors.rs` so NOTHING unwraps or panics:

```rust
use std::fs;

// typed, std-only error model (goose would reach for anyhow/thiserror — see notes)
fn read_model_config(path: &str) -> Result<String, String> {
    let raw = fs::read_to_string(path).map_err(|e| format!("cannot read {path}: {e}"))?;
    let line = raw.lines().next().ok_or("config is empty")?;
    let mut parts = line.split(':');
    let name = parts.next().ok_or("missing model name")?;
    let temp: f32 = parts
        .next()
        .ok_or("missing temperature")?
        .parse()
        .map_err(|e| format!("bad temperature: {e}"))?;
    Ok(format!("{} @ {}", name, temp))
}

fn main() {
    match read_model_config("config.txt") {
        Ok(summary) => println!("ok: {}", summary),
        Err(e) => println!("ERROR: {}", e),
    }
    match read_model_config("missing.txt") {
        Ok(_) => println!("unexpected success"),
        Err(e) => println!("ERROR: {}", e),
    }
    println!("ERR-OK");
}
```

Key moves to note in `lab13-notes.md` (map each to its replacement):

| Seeded mistake | Replacement | Why |
|---|---|---|
| `.unwrap()` on read | `.map_err(...)?` | context + early return |
| `.next().unwrap()` | `.ok_or("...")?` | typed absence reason |
| `.parse().unwrap()` | `.map_err(...)?` | parse error becomes a story |

Compile, run, confirm both ERROR lines print and the program finishes clean
with `ERR-OK`:

```powershell
rustc --edition 2021 lab13-errors.rs -o lab13-errors.exe
.\lab13-errors.exe
```

## Step 4 — Decide the crate split (10 min)

In `lab13-notes.md` answer:

1. If `lab13-errors.rs` lived inside the goose app, which return type would
   goose's AGENTS.md rule suggest instead of `Result<String, String>`?
2. If your errors had to drive *retry policy* (rate limit → wait, refusal →
   stop), which style would you pick and why (hint: revisit
   `goose-provider-types/src/errors.rs`)?
3. Where does goose bridge the two — name the function and the crate from
   `errors.rs:94`.

## Verification

```powershell
$env:GOOSE_REPO = "C:\Users\admin\projects\goose"  # adjust to your checkout
powershell -File verify.ps1 -GooseRepo $env:GOOSE_REPO
```

Confirm `VERIFY PASSED`, then mark the lab verified in the app.

## Homework

- Add a third file path to main (`"malformed.txt"` containing `"gpt-4o:notanumber"`)
  and confirm the refactored code reports a clean parse error, still printing
  `ERR-OK`. In notes: which `?`/`.map_err` handled it?
- Open goose's root AGENTS.md and quote the error-handling rule in your notes —
  one line. (This rule is enforced in review; you'll apply it in Unit 2 PRs.)