# Lab 0.15 — Mini fake provider: async fn yielding a message stream

Timebox: 40-50 min. PowerShell 5.1, your local `goose` checkout
(`$env:GOOSE_REPO`). The lab creates `lab15-fakeprovider` (cargo project) in your
working folder; `verify.ps1` checks goose files + your project's content.

## Step 1 — Read the real fake provider (15 min)

Open `crates/goose/src/providers/testprovider.rs` and read lines 40-69
(struct) and 167-218 (trait impl). In `lab15-notes.md`:

1. What does `records: Arc<Mutex<HashMap<String, TestRecord>>>` protect, and
   who needs to touch it (record mode vs replay mode)?
2. Why does `hash_input` run *outside* the lock — what would go wrong if hashing
   ran while holding `records.lock()`?
3. How does `stream_from_single_message` (base.rs:457-459) turn one `Message`
   into a `MessageStream`?

Also skim `crates/goose/src/agents/types.rs:7` — one sentence decoding the
double-Arc type.

## Step 2 — Scaffold (10 min)

```powershell
cargo new lab15-fakeprovider
Set-Location lab15-fakeprovider
cargo add tokio --features macros,rt,rt-multi-thread,time
cargo add futures
cargo add async-trait
cargo add anyhow
```

Replace `src/main.rs`:

```rust
use anyhow::Result;
use futures::{stream, Stream};
use std::collections::HashMap;
use std::pin::Pin;
use std::sync::{Arc, Mutex};
use tokio::time::{sleep, Duration};

use core::fmt;

#[derive(Clone)]
struct FakeMessage {
    text: String,
}

impl fmt::Display for FakeMessage {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.text)
    }
}

// the trait our provider implements — a tiny stand-in for goose's Provider
#[async_trait::async_trait]
trait MiniProvider: Send + Sync {
    fn get_name(&self) -> &str;

    // goose's contract: stream yields (Option<Message>, Option<Usage>) items
    async fn stream(
        &self,
        system: &str,
        messages: &[FakeMessage],
    ) -> Result<MessageStream, String>;
}

type MessageStream = Pin<
    Box<dyn Stream<Item = Result<(Option<FakeMessage>, Option<u32>), String>> + Send>,
>;

// the mini fake provider: lock-guarded call log, like TestProvider's records
struct EchoProvider {
    name: String,
    call_log: Arc<Mutex<HashMap<String, usize>>>,
    seed_count: Arc<Mutex<usize>>,
}

#[async_trait::async_trait]
impl MiniProvider for EchoProvider {
    fn get_name(&self) -> &str {
        &self.name
    }

    async fn stream(
        &self,
        system: &str,
        messages: &[FakeMessage],
    ) -> Result<MessageStream, String> {
        // log the call (lock-guarded shared state, exactly like testprovider.rs)
        let key = format!("{}#{}", system.len(), messages.len());
        {
            let mut log = self.call_log.lock().unwrap();
            *log.entry(key.clone()).or_insert(0) += 1;
        }

        // seeded counter: makes each call's output deterministic-ish
        let n = {
            let mut guard = self.seed_count.lock().unwrap();
            *guard += 1;
            *guard
        };

        let parts: Vec<FakeMessage> = vec![
            format!("[{name}] echo: system has {sys_len} chars, {msg_len} messages",
                name = self.name, sys_len = system.len(), msg_len = messages.len()),
            format!("[{name}] part 2/3 (call #{n})", name = self.name),
            format!("[{name}] part 3/3: done", name = self.name),
        ]
        .into_iter()
        .map(|text| FakeMessage { text })
        .collect();

        // real yielding stream: sleeps then yields, like a slow LLM
        let log = self.call_log.lock().unwrap().clone(); // snapshot AFTER our increment
        let stream = stream::unfold(0usize, move |i| {
            let parts = parts.clone();
            let log = log.clone();
            async move {
                if i >= parts.len() {
                    return None;
                }
                sleep(Duration::from_millis(30)).await;
                let mut result = Some(parts[i].clone());
                if i == parts.len() - 1 {
                    result = Some(FakeMessage {
                        text: format!(
                            "{}, total_calls={}",
                            parts[i].text,
                            log.values().sum::<usize>()
                        ),
                    });
                }
                Some((Ok((result, Some(10u32))), i + 1))
            }
        });
        Ok(Box::pin(stream) as MessageStream)
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    let provider = Arc::new(EchoProvider {
        name: "echo".into(),
        call_log: Arc::new(Mutex::new(HashMap::new())),
        seed_count: Arc::new(Mutex::new(0)),
    });

    let sys = "You are goose-lite";
    let msgs = vec![FakeMessage { text: "hello".into() }];

    // two concurrent streams share the provider's locked state
    let p1 = Arc::clone(&provider);
    let p2 = Arc::clone(&provider);
    let (_r1, _r2) = tokio::join!(
        async move { collect(p1, sys, &msgs).await },
        async move { collect(p2, sys, &msgs).await },
    );
    println!("FAKE-OK");
    Ok(())
}

async fn collect(
    provider: Arc<EchoProvider>,
    system: &str,
    messages: &[FakeMessage],
) -> Option<String> {
    let stream = provider.stream(system, messages).await.ok()?;
    let mut out = String::new();
    futures::pin_mut!(stream);
    let mut missed = false;
    while let Some(item) = futures::StreamExt::next(&mut stream).await {
        match item {
            Ok((Some(msg), _usage)) => {
                if !out.is_empty() {
                    out.push_str(" | ");
                }
                out.push_str(&msg.to_string());
            }
            Ok((None, _)) => missed = true,
            Err(_e) => missed = true,
        }
    }
    if missed {
        return None;
    }
    println!("{}", out);
    Some(out)
}
```

Wait — before you run: the `missed` logic above returns `None` only when
`None` items appear. Confirm by hand that `total_calls` reaches 2 (two
concurrent streams each increment the shared log). Then run:

```powershell
cargo run
```

## Step 3 — Provoke the classic async mistake (5 min)

A `std::sync::MutexGuard` must NEVER be held across an `.await` (the future
stops being `Send`, and goose's streams are `Send`). Prove it: inside the
`stream::unfold` closure (step 2 code), right BEFORE
`sleep(Duration::from_millis(30)).await;`, insert:

```rust
let _guard = self.seed_count.lock().unwrap();
```

Run `cargo check` and read the error — it should mention the future not being
sendable safely across threads (the `+ Send` bound on our `MessageStream`).
That error is why goose keeps critical sections short and never touches locks
across awaits. Remove the line, restore `cargo run`, and write ONE sentence in
`lab15-notes.md` about what the compiler just prevented.

## Step 4 — Map to real goose (10 min)

In `lab15-notes.md` build the mapping table:

| My lab15 code | Real goose (crate/file) |
|---|---|
| `trait MiniProvider` | `Provider` at `goose-provider-types/src/base.rs:464` |
| `type MessageStream` | `MessageStream` at `base.rs:327` |
| `Arc<Mutex<HashMap<..>>>` | `records` at `crates/goose/src/providers/testprovider.rs:41` |
| `stream::unfold` yielding `Ok((msg, usage))` | `stream_from_single_message` at `base.rs:457` |

## Verification

Run the check script **from the folder containing `lab15-fakeprovider\`**:

```powershell
$env:GOOSE_REPO = "C:\Users\admin\projects\goose"  # adjust to your checkout
powershell -File verify.ps1 -GooseRepo $env:GOOSE_REPO
```

Confirm `VERIFY PASSED`, then mark the lab verified in the app.

## Homework

- Make `EchoProvider`'s stream yield exactly two items per call (no third
  "done" part) and keep `total_calls` correct. Re-run.
- Look at the Unit 0 exam folder next — the mini-lab builds a *complete* echo
  agent (struct + trait + anyhow + serde + async stream + lock state). Your
  lab15 is 80% of it.