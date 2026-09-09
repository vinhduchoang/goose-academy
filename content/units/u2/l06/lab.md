# Lab 2.6 — Fix a parity bug in both paths; prove identical behavior

Timebox: 40-50 min. Read-only on the clone; your patch sketches and test plan
go in one artifact under `$env:U2LABS`.

## Step 1 — Ground the switch (10 min)

In the clone:

1. `crates/goose/src/agents/state_machine/mod.rs:73` — what values does
   `enabled()` accept? List all four accepted spellings.
2. `crates/goose/src/agents/agent.rs:1815` — what does
   `resume_state_machine_turn` do when `enabled()` is false? What does it
   return instead when the machine IS enabled? Then find the real reply handoff
   (around `agent.rs:2096`) — where else in `agent.rs` does
   `state_machine::enabled()` appear (grep)?
3. `crates/goose/src/agents/state_machine/tests/agent_reply.rs:133` and
   `agent.rs:5333` — which env-var values do these tests pin, via which
   helper?

Record answers in `$env:U2LABS\u2-l06-notes.md`.

## Step 2 — Locate both sites of the seeded bug (12 min)

The seeded bug: **tool-call result label truncated with a byte slice at 80
chars, panicking on multibyte input.** Find the real file each site would
live in (do not edit):

```powershell
Set-Location $env:GOOSE_REPO
Select-String -Path crates\goose\src\agents\agent.rs       -Pattern "label|truncat|chars" | Select -First 10
Select-String -Path crates\goose\src\agents\state_machine\ops_toolcalling.rs -Pattern "label|ContentBlock|text" | Select -First 10
```

Write `u2-l06-parity.md` with:

- the legacy universe site: file + the shape of the patch (get(..)+fallback
  replacing the slice; note the decision you picked for the fallback);
- the state-machine universe site: file + the equivalent patch shape;
- a box explaining why byte-slicing a tool label breaks ONLY when the label
  contains non-ASCII (bind it to the `string_slice` lesson).

## Step 3 — Write the regression test ONCE and run it TWICE (15 min)

In `u2-l06-parity.md`, write a regression test sketch modeled on the repo's
own env pinning:

```rust
// sketch (adapt the real test helpers honestly)
#[cfg(test)]
mod parity {
    use super::*;

    #[test]
    fn tool_label_survives_multibyte_legacy() {
        let _guard = env_lock::lock_env([("GOOSE_STATE_MACHINE", Some("0"))]);
        assert_eq!(build_tool_label(&["réponse".repeat(20).as_str()]).chars().count(), 80);
    }

    #[test]
    fn tool_label_survives_multibyte_state_machine() {
        let _guard = env_lock::lock_env([("GOOSE_STATE_MACHINE", Some("1"))]);
        assert_eq!(build_tool_label(&["réponse".repeat(20).as_str()]).chars().count(), 80);
    }
}
```

Then define the run matrix explicitly in the same file:

```powershell
$env:GOOSE_STATE_MACHINE = "0"; cargo test -p goose parity
$env:GOOSE_STATE_MACHINE = "1"; cargo test -p goose parity
```

Answer in the file: why is asserting the SAME assertion under BOTH pins the
definition of parity here — what would a test that only pins one mode let
through the review?

<FounderLens>

The env pin matters in CI too: tests that forget to unpin `GOOSE_STATE_MACHINE`
pollute sibling tests in the same process run. That is why goose uses scope
guards (env_lock drops and restores), never a bare `set_var`. Mention in your
sketch how the guard restores the previous value.

</FounderLens>

## Step 4 — The PR description (8 min)

Add a `## Parity` section to `u2-l06-parity.md` as if it were your PR:

- one line stating the change is identical in both paths;
- the two commands from the run matrix with expected green;
- one sentence naming the helper mechanism (env_lock) a reviewer can grep for.

## Verification

```powershell
Set-Location $env:U2LABS
powershell -File <lesson-dir>\verify.ps1 -GooseRepo $env:GOOSE_REPO
```

## Homework

- Grep `crates/goose/src/agents/state_machine/ops_*.rs` for `unwrap(` and
  `expect(` — count each. Write one sentence on whether that density differs
  from legacy `agent.rs` and what parity implies about it.
- Find `14c00a451 feat: support tool approval in the state machine` in
  `git log` — one paragraph: how did that commit demonstrate the both-paths
  rule in its diff?