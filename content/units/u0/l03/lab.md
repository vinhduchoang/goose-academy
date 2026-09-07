# Lab 0.3 — String ops on prompts; fix planted String/&str mismatches

Timebox: 40-50 min. PowerShell 5.1, your local `goose` checkout
(`$env:GOOSE_REPO`). Scratch files go in one working folder; `verify.ps1` checks
that folder plus the goose repo.

## Step 1 — Read a real prompt (5 min)

Show the first 10 lines of goose's planner prompt:

```powershell
Get-Content "$env:GOOSE_REPO\crates\goose\src\prompts\plan.md" -TotalCount 10
```

In `lab03-notes.md`: record the first line, and whether this file is a `String`
or `&str`-style artifact at runtime *before* rendering (see `prompt_template.rs:7`
`include_dir!`).

## Step 2 — String-board exercise (15 min)

Create `lab03-board.rs`:

```rust
fn word_count(text: &str) -> usize {
    text.split_whitespace().count()
}

fn main() {
    // &str literal borrowed from the binary
    let plan_intro: &str = "You are a specialized planner AI.";

    // String: owned, growable — mimic a loaded prompt file
    let mut prompt = String::from(plan_intro);
    prompt.push_str(" Analyze the user request and create the steps.");
    let heading = prompt.replace("planner", "PLANNER");
    println!("words: {}", word_count(&prompt));
    println!("heading: {}", heading);
    println!("chars: {}", prompt.chars().count());
    println!("upper head: {}", plan_intro[..10].to_uppercase());

    // slice / Vec: split the prompt into Vec<&str> views (no copying!)
    let pieces: Vec<&str> = prompt.split(". ").collect();
    println!("pieces: {:?}", pieces);

    // tuple + array from the lesson
    let entry: (&str, usize) = ("plan.md", prompt.len());
    let lengths: [usize; 2] = [entry.1, pieces.len()];
    println!("entry {:?} lengths {:?}", entry, lengths);
    println!("BOARD-OK");
}
```

Compile and run:

```powershell
rustc --edition 2021 lab03-board.rs -o lab03-board.exe
.\lab03-board.exe
```

└────────────────────────────────┘

## Step 3 — Fix planted String/&str mismatches (15 min)

Each snippet below has one planted mistake. Copy the **fixed** function into
`lab03-fixes.rs` so the whole file compiles. Hint: ask "who owns the bytes?"

```rust
// 1. returning a borrowed 'static literal needs an explicit lifetime
//    (no input references -> elision cannot pick a source, only 'static works)
fn greeting() -> &str {
    "hello goose"   // planted: return type must be &'static str
}

// 2. a function that only READS should borrow, not take ownership
fn count_lines(text: String) -> usize {
    text.lines().count()   // planted: signature should be &str
}

// 3. you cannot index a String with s[0]; chars() is Unicode-aware
fn first_letter(s: &str) -> char {
    s[0]   // planted: use s.chars().next().unwrap_or('?')
}

// 4. growing a string needs ownership and mutability
fn append_marker(mut s: &str) {
    s.push_str(" END");   // planted: s must be &mut String
}

fn main() {
    let g: &str = greeting();
    println!("{} / {} lines", g, count_lines("a\nb\nc"));
    println!("first: {}", first_letter("goose"));
    let mut s = String::from("start");
    append_marker(&mut s);
    println!("{}", s);
    println!("FIXES-OK");
}
```

Fix all four, then:

```powershell
rustc --edition 2021 lab03-fixes.rs -o lab03-fixes.exe
.\lab03-fixes.exe
```

For each fix, write one line in `lab03-notes.md` stating the *rule* it
illustrates (e.g. "read-only access → borrow with &str").

## Step 4 — Read the registry (10 min)

Open `crates/goose/src/prompt_template.rs` and look at `TEMPLATE_REGISTRY`
(`prompt_template.rs:9`). In `lab03-notes.md` answer:

1. What two compound types nest together in `&[(&str, &str)]`?
2. Why is `&str` the correct inner type here — could it be `String`?
3. Where does the rendered `String` first appear (which file does the rendering
   call live in, per `prompt_manager.rs:143`)?

## Verification

```powershell
$env:GOOSE_REPO = "C:\Users\admin\projects\goose"  # adjust to your checkout
powershell -File verify.ps1 -GooseRepo $env:GOOSE_REPO
```

Confirm `VERIFY PASSED`, then mark the lab verified in the app.

## Homework

- Run `Get-Content "$env:GOOSE_REPO\crates\goose\src\prompts\system.md" -TotalCount 50`
  and find one `{{ jinja }}` template marker. One sentence in your notes: at what
  point does a `{{ variable }}` become a real value — compile time, file time, or
  render time?
- Count how many times `String` appears in
  `crates/goose/src/agents/prompt_manager.rs`'s `PromptManager` struct (line 19).
  Why is `system_prompt_override` an `Option<String>` instead of `Option<&str>`?