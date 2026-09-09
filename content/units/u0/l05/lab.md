# Lab 0.5 — Loop over `Vec<Message>`-like data; convert the for...of mental model

Timebox: 40-50 min. PowerShell 5.1, your local `goose` checkout
(`$env:GOOSE_REPO`). Scratch files in one working folder; `verify.ps1` checks
that folder plus the goose repo.

## Step 1 — Read the loops goose actually runs (10 min)

Open these and trace each loop/chain:

1. `crates/goose/src/token_counter.rs:78` — `for tool in tools`
2. `crates/goose/src/providers/usage_estimator.rs:30` — iterator chain building
   `response_text`

In `lab05-notes.md`:

- What does the loop at `token_counter.rs:78` accumulate, and what type is the
  accumulator?
- Write the TS translation of the `usage_estimator.rs:30` chain.

## Step 2 — Build conversational data (10 min)

Create `lab05-turns.rs`:

```rust
#[derive(Debug)]
struct Turn {
    role: String,
    text: String,
}

fn main() {
    let turns = vec![
        Turn { role: "user".into(), text: "hello goose".into() },
        Turn { role: "assistant".into(), text: "hi! how can I help?".into() },
        Turn { role: "user".into(), text: "count tokens".into() },
        Turn { role: "assistant".into(), text: "counting now".into() },
    ];

    // 1. for...in over references — nothing is moved
    let mut total_chars = 0usize;
    for t in &turns {
        total_chars += t.text.chars().count();
    }
    println!("total chars: {}", total_chars);

    // 2. while with a shrinking window
    let mut window = total_chars;
    while window > 10 {
        window /= 2;
    }
    println!("shrunk window: {}", window);

    // 3. loop + break with a value
    let assistant_words = loop {
        let mut w = 0;
        for t in &turns {
            if t.role == "assistant" {
                w += t.text.split_whitespace().count();
            }
        }
        break w;
    };
    println!("assistant words: {}", assistant_words);

    // 4. range + continue
    let mut non_multiples = Vec::new();
    for i in 0..=10 {
        if i % 3 == 0 { continue; }
        non_multiples.push(i);
    }
    println!("non-multiples of 3: {:?}", non_multiples);

    // 5. iterator chain (the FE style you already know)
    let user_text: Vec<&str> = turns
        .iter()
        .filter(|t| t.role == "user")
        .map(|t| t.text.as_str())
        .collect();
    println!("user turns: {:?}", user_text);

    // 6. if as an expression
    let verdict = if total_chars > 40 { "long chat" } else { "short chat" };
    println!("verdict: {}", verdict);
    println!("CONTROL-OK");
}
```

Compile and run:

```powershell
rustc --edition 2021 lab05-turns.rs -o lab05-turns.exe
.\lab05-turns.exe
```

## Step 3 — Break it on purpose (10 min)

In a copy `lab05-broken.rs`, plant exactly one of these mistakes, run rustc, and
save the error text into `lab05-notes.md`:

- Drop the `&` in `for t in turns` (watch the move error).
- Change one `if` expression branch to a different type (e.g. `if total_chars > 40
  { "long" } else { 99 }`).

Then run rustc and note, in `lab05-notes.md`, which line rustc points at
(`-->` arrow). The error is the lesson.

## Step 4 — Find the filter_map in real goose (10 min)

Open `crates/goose-provider-types/src/conversation/message.rs:989`. The chain
filters a message's content blocks to a single audience. In `lab05-notes.md`:

1. What does `filter_for_audience` return — and why does `filter_map` (not
   `map`) fit?
2. Write the equivalent TS one-liner using `.flatMap`.

## Verification

```powershell
$env:GOOSE_REPO = "C:\Users\admin\projects\goose"  # adjust to your checkout
powershell -File verify.ps1 -GooseRepo $env:GOOSE_REPO
```

Confirm `VERIFY PASSED`, then mark the lab verified in the app.

## Homework

- Add to `lab05-turns.rs` a seventh block: use `.enumerate()` over `&turns` to
  print `turn N: role`. Re-run to confirm it still prints `CONTROL-OK`.
- In `token_counter.rs`, find the *nested* loop over a tool's properties (near
  `token_counter.rs:90+`). One sentence: which construct guards it (`if let`)?
  (Keep the answer for lesson 0.6 — you will meet it again.)