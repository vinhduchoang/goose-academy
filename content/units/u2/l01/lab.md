# Lab 2.1 — Triage 3 real issues and file one new issue by template

Timebox: 40-50 min. PowerShell 5.1 against your local goose checkout
(`$env:GOOSE_REPO`). You will work in a learner directory (call it
`$env:U2LABS`, e.g. `C:\Users\admin\projects\u2-labs` — create it first).

## Step 1 — Read the protocol (5 min)

Open `AGENTS.md` at your checkout (`AGENTS.md:7-15`) and write down, in your
own words, the four board statuses and what each means for a contributor.
Keep it in a scratch note — you will reuse it in Step 3.

## Step 2 — Triage 3 real past issues (15 min)

The goose git history is your issue archive. List recent fixes and read three:

```powershell
Set-Location $env:GOOSE_REPO
git log --oneline --grep="token_counter"
git log --oneline --grep="large response" -i
git show 509fcac69 --stat
git show e7c33077c --stat
```

For each of the three issues below, classify with one status word from
**Inbox / Needs info / Accepted / Ready / Done** and justify one sentence:

| Issue | Hints |
|---|---|
| #4632 — panic in `token_counter` with GitHub Copilot (fixed in `509fcac69`) | look at the +3/-1 diff: was it a behavior change? |
| #9586 — LRU cache for token counting (`08e748051`) | 47 insertions — feature or bug fix? |
| #10482 — secure large response spill files (`e7c33077c`) | which template type would this have used at filing time? |

Write your triage into `$env:U2LABS\u2-l01-triage.md` — one line per issue:
`#4632 | <status> | <one-sentence reason>`.

## Step 3 — File one new issue by template (20 min)

A real improvement you must have run into by now: in your checkout,
`.github/ISSUE_TEMPLATE/config.yml` sets `blank_issues_enabled: false`, so
*any* issue must match a template. Write a **complete new bug report** in
`$env:U2LABS\u2-l01-issue.md` about this real defect:

> `goose run --recipe` with a recipe whose `parameters` declare a `required`
> key silently proceeds when the value is omitted instead of failing fast.

Before writing, open `.github/ISSUE_TEMPLATE/bug_report.md` and follow its
exact section order:

- **Describe the bug** — clear and concise
- **To Reproduce** — numbered steps (include a minimal recipe snippet)
- **Expected behavior** vs **Actual behavior**
- **Environment** — goose version (an exact `git rev-parse HEAD` or the
  version from `cargo metadata`), OS, install method
- Mention which diagnostics you would attach (`bug_report.md:14` asks for the
  diagnostics zip — say where you generated it from)

Make the title follow `type: terse summary` style with `type` = bug.

<FounderLens>

`gh issue create` does not apply templates automatically — that's why the
issue body you write by hand gets judged against the template. Maintainers
triage by skimming the **To Reproduce** block first: an issue with solid repro
steps jumps the queue because it's already half a verification plan for the
PR that fixes it. Bad repro = Needs info limbo.

</FounderLens>

## Verification

```powershell
powershell -File verify.ps1 -GooseRepo $env:GOOSE_REPO
```

Run from `$env:U2LABS` so the script finds your artifact files.

## Homework

- Pick one of the three historical issues above and write the first **PR
  comment** you would post for it: link the issue, lead with the conclusion,
  one paragraph max (AGENTS.md GitHub Communication rules).
- Look at the Goose Issues board link in `AGENTS.md:7`. List three issues
  currently marked **Ready** (title + one line on its verification plan).