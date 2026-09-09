# Lab 1.1 — Build the real dependency graph with cargo metadata

Timebox: 40-50 min. All PowerShell 5.1, against your goose checkout
(`$env:GOOSE_REPO`, default `C:\Users\admin\projects\goose`).

Goal: produce a real, verified crate-graph artifact (a `.dot` file + an edge table
in markdown) so the dependency direction claim in the theory is something *you*
extracted, not something you read.

## Step 1 — Dump raw metadata (5 min)

```powershell
Set-Location $env:GOOSE_REPO
cargo metadata --no-deps --format-version 1 | Out-File u1l01-metadata.json -Encoding utf8
```

Inspect one package's dependency entries. Edges to workspace members carry a
`path` field; external edges do not:

```powershell
$m = Get-Content u1l01-metadata.json -Raw | ConvertFrom-Json
$m.packages | Where-Object name -eq "goose-providers" | ForEach-Object { $_.dependencies } |
  Select-Object name, path | Format-List
```

## Step 2 — Emit a GraphViz dot file (15 min)

Write a script block that walks `$m.packages` and emits DOT. Keep two edge kinds:
*solid* for workspace edges (`path` present), *dashed* for the (top 3) external
deps per crate you care about (`rmcp`, `serde`, `tokio`). Sketch:

```text
digraph goose {
  rankdir=BT;                  # sinks at bottom
  "goose-sdk-types" -> "agent-client-protocol" [style=dashed];
  "goose-provider-types" -> "rmcp" [style=dashed];
  "goose-providers" -> "goose-provider-types";
  "goose" -> "goose-providers";
  "goose-cli" -> "goose"; ...
}
```

Save it as `l01-graph.dot` in your scratch dir. Render it if you have GraphViz
(`dot -Tpng l01-graph.dot -o l01-graph.png`); otherwise just read it — direction
*is* the point.

## Step 3 — Extract the edge table (10 min)

From the same `$m.packages`, build the table by hand (or a foreach) with columns:
crate, workspace deps, notable external deps. Cross-check against the theory's
claims. Write it into `l01-workspace-notes.md`, and answer:

1. Which crates have zero workspace dependencies (the sinks)?
2. Which crate is depended on by the most workspace crates?
3. `goose` depends on `goose-providers` — walk the chain goose-cli → goose →
   goose-providers → goose-provider-types and write one line of evidence per edge
   (a file + line proving the dependency). Hint for the last edge:
   `crates/goose-providers/src/lib.rs:8`; for goose's side,
   `crates/goose/src/lib.rs:15`.

## Step 4 — The founder-lens check (10 min)

In `l01-workspace-notes.md`, answer with file evidence:

1. Could `goose-provider-types` depend on `goose` today? Read
   `crates/goose-provider-types/Cargo.toml` — what would break architecturally if
   a contributor added such an edge and CI merged it anyway?
2. `vendor/v8` is listed in the root `Cargo.toml:5` members — why is it there?
   (Read the comment right above it.) What does that tell you about tools that
   inspect the workspace by globbing `crates/*`?

## Verification

```powershell
$env:GOOSE_REPO = "C:\Users\admin\projects\goose"  # adjust to your checkout
powershell -File verify.ps1 -GooseRepo $env:GOOSE_REPO
```

Expect `VERIFY PASSED`. Then mark the lab verified in the app.

## Homework

- Extend Step 2's script into a reusable snippet you keep in a scratch file: it
  must print "CYCLE DETECTED" if any workspace cycle exists and exit 0 otherwise.
  We will use this in Unit 2's review drills.
- `cargo metadata` has a `--filter-platform` flag. One sentence in your notes:
  why does a *host-platform* filter matter for provider crates like
  `goose-local-inference`?