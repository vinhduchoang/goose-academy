# Lab 2.2 — Reproduce a seeded bug and bisect it to the commit

Timebox: 40-50 min. All work in `$env:U2LABS` (create if missing). No cargo
needed — the bisect skill is the deliverable.

## Step 1 — Build the seeded history (10 min)

Create a scratch git repo whose history contains a hidden regression:

```powershell
New-Item -ItemType Directory -Force -Path "$env:U2LABS\u2-l02-scratch"
Set-Location "$env:U2LABS\u2-l02-scratch"
git init
```

Create `Get-Label.ps1` with this content (first commit, healthy):

```powershell
function Get-Label {
    param([int]$InputSize)
    if ($InputSize -gt 1000) { return "big-input" }
    if ($InputSize -gt 100)  { return "medium-input" }
    return "small-input"
}
```

Commit 1..3: commit the file, then add a comment line and a second helper
`Get-LabelJSON` on commits 2-3 — all healthy. Commit 4 (**the regression**):
change the `-gt 1000` condition to `-gt 999` (a classic off-by-one fencepost —
inputs of exactly 1000 now get the wrong label). Commit 5-6: unrelated changes
(rewrite a doc comment, reorder a string) that do NOT fix anything.

Use this commit helper so git never prompts for identity:

```powershell
function C { param([string]$m); git add -A;
  git -c user.name="learner" -c user.email="learner@academy" commit -m $m }
C "step1: healthy Get-Label"
```

Tag the first known-good state: `git tag known-v1 HEAD~5` — or annotate later
from the log.

## Step 2 — Write the repro as a script (8 min)

Put the regression in a script returning non-zero when the bug is present:

```powershell
# check.ps1 — exit 0 if healthy, 1 if the regression is present
. .\Get-Label.ps1
$label = Get-Label -InputSize 1000
if ($label -ne "medium-input") { Write-Host "BUG: got $label"; exit 1 }
exit 0
```

Confirm: on latest commit it fails, on `known-v1` it passes. If both behave
alike, your plant is wrong — fix it now; reproducing first is the whole point.

## Step 3 — Bisect (12 min)

```powershell
git bisect start
git bisect bad HEAD
git bisect good known-v1
```

Git checks out a midpoint. Run `.\check.ps1` and mark `git bisect bad` or
`git bisect good` accordingly. Repeat (about 2-3 runs for 6 commits). When git
prints the first bad commit, capture the session record:

```powershell
git bisect log > "$env:U2LABS\bisect-log.md"
git bisect reset
```

## Step 4 — Ground it in real history (15 min)

In the real clone, reproduce *historically* — no runtime needed:

```powershell
Set-Location $env:GOOSE_REPO
git log --oneline -8 -- crates/goose/src/token_counter.rs
git show 509fcac69
git show --stat 08e748051
```

Write `real-gitlog.md` into `$env:U2LABS`:

1. The +3/-1 lines of `509fcac69` — what was the panic root cause pattern
   (look for `expect`/`unwrap`/`.map()` in the diff)?
2. Why `08e748051` (LRU cache) is behavior-preserving yet perf-critical —
   one sentence tying it to `token_counter.rs:12`.
3. Your own bisect verdict from Step 3: the planted commit's SHA, the number
   of `check.ps1` runs it took.

<FounderLens>

`git bisect run .\check.ps1` would have done Step 3 without you — try it after
step 3 once to see the automation. Maintainers treat "I bisected it" as the
gold standard of bug reports because it converts "something is wrong" into
"this exact commit did it", which is half the root-cause analysis done.

</FounderLens>

## Verification

```powershell
Set-Location $env:U2LABS
powershell -File <lesson-dir>\verify.ps1 -GooseRepo $env:GOOSE_REPO
```

## Homework

- Re-run Step 3 fully with `git bisect run .\check.ps1` and compare the output
  text with your manual session.
- In the clone, `git show a82a1d7de` — write one sentence on how that fix
  chose `Result` over `panic` and why that matches goose's error conventions.