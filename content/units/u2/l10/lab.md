# Lab 2.10 — Review 2 planted diffs; catch every violation

Timebox: 40-50 min. No builds — this is pure review craft plus clone policy
reading.

## Step 1 — Re-read the review sources (10 min)

In the clone:

1. `AGENTS.md` Rules + Never sections (`AGENTS.md:91-119`) — list both
   sections' bullets in your notes.
2. `deny.toml` (repo ROOT — check that first; a plan-era document mentioned
   `rust-toolchain/deny.toml`, note where it actually is now) — record the
   three advisory levels and the reason attached to the ignored RUSTSEC.
3. `.github/recipes/code-review.yaml` — first 10 lines: what is it, a recipe
   for whom?

Save `$env:U2LABS\u2-l10-notes.md`.

## Step 2 — Review the two planted diffs (20 min)

Create the review target: `New-Item -ItemType Directory -Force
"$env:U2LABS\u2-l10-review"`, then drop these two diff files in it (copy
verbatim into `diff1.diff` and `diff2.diff`):

```diff
--- a/crates/goose/src/agents/agent.rs
+++ b/crates/goose/src/agents/agent.rs
@@ fix: truncate tool label to 80 chars
 fn tool_label(text: &str) -> String {
-    text.to_string()
+    // Initialize the result buffer
+    let mut result = String::new();
+    let label = &text[..80];              // string_slice: multibyte panic
+    result.push_str(label);
+    result
 }
@@ parity: no change to ops_toolcalling.rs path discussed
```

```diff
--- a/crates/goose/Cargo.toml
+++ b/crates/goose/Cargo.toml
@@ hand-edited dependency entries
+dependencies:
+  shiny-helper = "1.2.3"                  # no cargo add, no lockfile update
--- a/crates/goose/src/providers/base.rs
+++ b/crates/goose/src/providers/base.rs
 fn load_tokenizer() -> CoreBPE {
-    get_tokenizer().map_err(|e| anyhow!("{e}"))?
+    get_tokenizer().unwrap()               # panic path; anyhow doctrine violated
 }
```

Write `u2-l10-findings.md` — one numbered finding per violation, each
with: the violation, the *rule source that would catch it* (AGENTS.md line /
deny.toml clause / workspace lint), and the fix. Expected floor: **8
findings**. Hunt: byte-slice panic, restating comment, missing parity change,
hand-edited Cargo.toml, missing lockfile sync, `unwrap` on fallible path,
plus the subtle ones — which gate (`check-everything` just) would catch each
automatically vs which need human eyes?

## Step 3 — Rank them like a maintainer (10 min)

Append a `## Verdict` section to `u2-l10-findings.md`: block the PR with one
comment — the single most severe finding — plus your requested changes list,
then say in one line *why* the blocker is the blocker (security/parity/correctness
> style).

Then answer in `u2-l10-notes.md`: why does a comment that merely restates the
code violate AGENTS.md's Code Quality section even though it "hurts nothing"?

## Verification

```powershell
Set-Location $env:U2LABS
powershell -File <lesson-dir>\verify.ps1 -GooseRepo $env:GOOSE_REPO
```

## Homework

- Find one real merged PR in the clone where the diff touches BOTH
  `agents/agent.rs` and a `state_machine/` file (`git log --oneline --stat |
  head`), and write one paragraph on how it honored the parity rule.
- Read `.github/workflows/goose-pr-reviewer.yml` header — one paragraph: how
  does the repo automate PR review with goose itself?