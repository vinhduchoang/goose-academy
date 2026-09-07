# Lab 0.14 — Round-trip model_config-style JSON; add a backward-compat field

Timebox: 40-50 min. PowerShell 5.1, your local `goose` checkout
(`$env:GOOSE_REPO`). The lab creates a small cargo project in your working
folder; `verify.ps1` checks goose files + your project's content.

## Step 1 — Read the serde attributes in real goose (10 min)

Open and note each attribute's *purpose* in `lab14-notes.md`:

1. `model.rs:40` — derive list on ModelConfig
2. `model.rs:43` and `model.rs:58` — the two `#[serde(skip)]` fields
3. `model.rs:50` — `default` + `skip_serializing_if`
4. `message.rs:961` — `rename_all = "camelCase"`
5. `agents/types.rs:60` — `tag = "type"` on an enum

## Step 2 — Scaffold a serde scratch crate (10 min)

```powershell
cargo new lab14-serde
Set-Location lab14-serde
cargo add serde --features derive
cargo add serde_json
```

Replace `src/main.rs` with a model_config-style struct:

```rust
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "camelCase")]
struct ModelConfig {
    model_name: String,
    temperature: Option<f32>,
    // NEW FIELD (step 4): must default when absent
    #[serde(default, skip_serializing_if = "Option::is_none")]
    reasoning: Option<bool>,
    // never on the wire
    #[serde(skip)]
    api_key: Option<String>,
}

fn main() {
    // serialize: Option fields vanish when None (skip_serializing_if works above)
    let config = ModelConfig {
        model_name: "gpt-4o".into(),
        temperature: Some(0.7),
        reasoning: None,
        api_key: Some("sk-secret".into()),
    };
    let json = serde_json::to_string_pretty(&config).unwrap();
    println!("{}", json);

    // round-trip: old-shape JSON (no reasoning key) must still parse
    let old_json = r#"{ "modelName": "gpt-4o", "temperature": 0.5 }"#;
    let parsed: ModelConfig = serde_json::from_str(old_json).unwrap();
    println!("parsed old-shape: {:?}", parsed);
    assert!(parsed.reasoning.is_none(), "default applied");
    assert!(parsed.api_key.is_none(), "skip means not deserialized");

    // round-trip equality
    let again = serde_json::to_string(&parsed).unwrap();
    let back: ModelConfig = serde_json::from_str(&again).unwrap();
    assert_eq!(back, parsed);
    println!("SERDE-OK");
}
```

## Step 3 — Run the round-trip (10 min)

```powershell
cargo run
```

Record in `lab14-notes.md`:

1. Did the serialized JSON contain `apiKey`? Why not?
2. What did the old-shape parse prove — which attribute did the work?
3. What key name appears for `model_name` on the wire, and which attribute
   caused it?

## Step 4 — Add the field (10 min — the lab's core)

The struct above already shows the finished state; the exercise is to *prove
the sequence*. Do it in this order and note each compile/run behavior in
`lab14-notes.md`:

1. Add `reasoning: Option<bool>` **without** any attribute; `cargo build` and
   note what happens when you feed `old_json` at runtime (the parse error).
2. Add `#[serde(default, skip_serializing_if = "Option::is_none")]`; re-run —
   the old-shape JSON parses again and prints `reasoning: None`.
3. Observe the wire: with `Some(true)` set, the field appears; with `None` it
   disappears. One sentence: which attribute performs which half?

## Step 5 — Enum on the wire (10 min)

Append to `src/main.rs` a Goose-shaped enum and print both directions:

```rust
#[derive(Debug, Serialize, Deserialize, PartialEq)]
#[serde(tag = "type")]
enum SuccessCheck {
    Shell { command: String },
}

fn enum_roundtrip() {
    let check = SuccessCheck::Shell { command: "cargo test".into() };
    let j = serde_json::to_string(&check).unwrap();
    println!("{}", j);
    let back: SuccessCheck = serde_json::from_str(&j).unwrap();
    assert_eq!(back, check);
}
```

Call `enum_roundtrip()` from `main`, run again, and paste the JSON shape into
`lab14-notes.md`.

## Verification

Run check script **from your lab working folder** (the folder containing
`lab14-serde\`):

```powershell
$env:GOOSE_REPO = "C:\Users\admin\projects\goose"  # adjust to your checkout
powershell -File verify.ps1 -GooseRepo $env:GOOSE_REPO
```

Confirm `VERIFY PASSED`, then mark the lab verified in the app.

## Homework

- Read `model.rs:62-100`. One sentence in notes: why does ModelConfig hand-write
  `Deserialize` instead of deriving it?
- `serde_json::from_str` on junk (e.g. `"{ not json"`) errors with what in
  Rust — a panic, an Err, an exception? Demonstrate in a scratch line and note
  the error type you got.