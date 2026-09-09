# Lab 2.8 — Rebuild, run goose run --recipe, add a scenario

Timebox: 40-50 min. Clone + one scratch addition.

## Step 1 — Study the suite skeleton (10 min)

```powershell
Get-Content $env:GOOSE_REPO\goose-self-test.yaml -TotalCount 60
```

Record in `$env:U2LABS\u2-l08-notes.md`:

1. The exact parameter keys at `goose-self-test.yaml:23` and their defaults.
2. Two `activities` lines that you could *demonstrably* map to a PR you could
   write this week (one sentence each).
3. Which phase block contains the nested-delegation CRITICAL test, and what
   outcome would flip the suite to FAIL (read the block).

## Step 2 — Rebuild, then run the recipe (15 min)

```powershell
Set-Location $env:GOOSE_REPO
cargo build -p goose-cli --bin goose          # first run: minutes, later: fast
goose run --recipe goose-self-test.yaml --help # confirm the flag resolves
```

Now attempt the real run with a phase parameter to keep it bounded:

```powershell
goose run --recipe goose-self-test.yaml --params test_phases=basic
```

Three honest outcomes — record whichever happens in `u2-l08-runlog.md`:

- **Full success**: paste the executive summary block.
- **Partial**: paste the phase logs it did produce + the error line.
- **Blocked (no provider / no key configured)**: paste the exact error
  message about provider configuration, then write the *planned* command plus
  what Phase 1's file operations scenario would tell you (read it in the
  recipe prompt).

A genuine skip with the exact blocker is fine — recipe runs need a provider;
pretending you ran it is the only failure mode.

## Step 3 — Add your scenario (12 min)

Build `$env:U2LABS\u2-l08-scenario.yaml` — NOT by editing the real file. Your
file mirrors the recipe skeleton and adds one scenario:

- `activities:` gain one line: e.g. "Validate UTF-8-safe label fitting".
- `parameters:` — add one parameter `label_max_chars` (default "80",
  description says what it bounds).
- `prompt:` — one phase block with the `{% if %}` guard pattern: run the
  fit_label exercise from l07 (compile scratch binary, feed a multibyte
  label, log the result to `{{ workspace_dir }}/phase_label_fitting.md`, and
  report in the final summary).

Then in `u2-l08-notes.md`, append:

- which phase of the real `goose-self-test.yaml` your scenario joins, and
  why (match the phase naming: basic / extensions / delegation / reasoning /
  acp-effort / advanced);
- one line proving your guard condition only runs when selected;
- one line naming the success criterion rule (80%) your scenario must not
  violate.

## Step 4 — Plan the PR statement (8 min)

Write the 4-line "Testing" section you would put on the PR for the l07
feature, in `u2-l08-runlog.md`:

- unit/integration tests run;
- recipe updated (file + which activity line);
- rebuild command;
- `goose run --recipe goose-self-test.yaml --params test_phases=<yours>` + observed
  verdict.

## Verification

```powershell
Set-Location $env:U2LABS
powershell -File <lesson-dir>\verify.ps1 -GooseRepo $env:GOOSE_REPO
```

## Homework

- Read `workflow_recipes/release_risk_check/recipe.yaml` lines 1-10. Explain
  how `{{recipe_dir}}` lets a recipe be relocated without breaking its own
  script reference.
- Draft ONE more self-test scenario for a capability you'd add if you owned
  the suite: activity line + three concrete assertion steps + the log file it
  must produce (homework note, not a YAML).