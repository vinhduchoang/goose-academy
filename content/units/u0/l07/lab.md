# Lab 0.7 — Fix move errors; identify and explain .clone() sites in goose

Timebox: 40-50 min. PowerShell 5.1, your local `goose` checkout
(`$env:GOOSE_REPO`). Scratch files in one working folder; `verify.ps1` checks
that folder plus the goose repo.

## Step 1 — Read the clone sites (10 min)

Open these and read the surrounding 3 lines each:

1. `crates/goose/src/providers/testprovider.rs:111`
2. `crates/goose/src/providers/testprovider.rs:194`
3. `crates/goose-provider-types/src/conversation/message.rs:994`

In `lab07-notes.md`, for each: what is cloned, and *what would break* (or what
would have to be written differently) without the clone?

## Step 2 — Meet the move error (15 min)

Create `lab07-moves.rs`:

```rust
#[derive(Clone)]
struct Draft {
    title: String,
    body: String,
}

fn publish(d: Draft) -> String {
    format!("published: {}", d.title)
}

fn main() {
    let draft = Draft {
        title: "goose v1.49 notes".into(),
        body: "ownership day".into(),
    };
    // Planted mistake 1: publish takes ownership by value
    // println!("still have: {}", draft.title);  // E0382 if uncommented

    let headline = publish(draft.clone()); // fix A: clone before the move
    println!("{}", headline);
    println!("still have: {}", draft.title);

    // Planted mistake 2: copy vs move
    let a = String::from("session");
    let b = a;          // move, not copy
    let mut c = b.clone(); // fix B: explicit clone restores a copy
    c.push_str("s");
    // println!("a={} b={} c={}", a, b, c); // a is dead even after fixes? check!
    println!("b={} c={}", b, c);

    // Planted mistake 3: loop moves the Vec's elements
    let labels = vec![String::from("one"), String::from("two")];
    for l in &labels {          // fix C: iterate by reference
        println!("{}", l);
    }
    println!("labels alive: {:?}", labels);
    println!("MOVES-OK");
}
```

Uncomment the two planted-mistake `println!` lines one at a time, compile, and
read the E0382 error (paste it into `lab07-notes.md`). Then apply the fixes
shown and make the file compile clean:

```powershell
rustc --edition 2021 lab07-moves.rs -o lab07-moves.exe
.\lab07-moves.exe
```

## Step 3 — Copy vs clone experiment (10 min)

In `lab07-notes.md` answer with proof from *your own* compiles:

1. Is `usize` Copy? (Try using a variable twice after passing it by value.)
2. Is `String` Copy? What error category says so (E0382 move / E0507)?
3. Write the type that is "cheap to copy" for goose's TokenCacheKey
   (`token_counter.rs:27` — read its derive list) and say which of its fields
   make it Copy.

## Step 4 — Find clone() sites in goose yourself (10 min)

Run this and write down 3 results with your explanation:

```powershell
Select-String -Path "$env:GOOSE_REPO\crates\goose\src\providers\testprovider.rs" -Pattern '\.clone\(\)' | Select-Object -First 5 LineNumber, Line
```

For each: why is a copy needed *there* (record/replay? keying? ownership boundary)?
Put your answers in `lab07-notes.md`.

## Verification

```powershell
$env:GOOSE_REPO = "C:\Users\admin\projects\goose"  # adjust to your checkout
powershell -File verify.ps1 -GooseRepo $env:GOOSE_REPO
```

Confirm `VERIFY PASSED`, then mark the lab verified in the app.

## Homework

- In `crates/goose/src/token_counter.rs`, find `TokenCacheKey` and its
  `blake3::hash` field (`[u8; 32]`). Is `[u8; 32]` Copy? (Check the derive on
  the struct — answer in notes.)
- Write one sentence for each: what memory is freed, and when, for (a) a
  `String` local in a function that returns nothing, (b) a `Vec<Turn>` you
  built in main.