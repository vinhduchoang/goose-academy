# Lab 3.10 — Capstone: ship your own production-grade extension

Timebox: 40-50 min (finish unfinished parts as homework — the final exam's
miniLab grades this exact artifact set). PowerShell 5.1, your goose checkout
(`$env:GOOSE_REPO`).

```powershell
$env:LAB10 = Join-Path (Get-Location) "goose-labs\u3-l10"
$env:CAPSTONE = Join-Path $env:LAB10 "capstone-ext"
New-Item -ItemType Directory -Force -Path $env:CAPSTONE | Out-Null
```

## Step 1 — Pick the workflow and justify the surface (10 min)

Write `docs\design.md` with three sections:

1. **Problem** — one paragraph on the real friction you will remove.
2. **Surface choice** — MCP server, plugin, or provider — and one paragraph
   why (server = stateful tools; plugin = prompts/skills/hooks; provider =
   model access). Cite the matching reference file: `mcp` →
   `crates/goose-mcp/src/memory/mod.rs:390`; plugin →
   `crates/goose/src/hooks/mod.rs:1`; provider →
   `crates/goose-provider-types/src/base.rs:464`.
3. **Security model** — what each tool may touch, read-only vs write,
   secrets (env_keys / none), and what the extension explicitly cannot do.

## Step 2 — Scaffold the repo layout (10 min)

```powershell
New-Item -ItemType Directory -Force -Path (Join-Path $env:CAPSTONE "src"), (Join-Path $env:CAPSTONE "tests"), (Join-Path $env:CAPSTONE "docs") | Out-Null
Set-Location $env:CAPSTONE
```

Pick A or B:

**A — MCP server route:** `cargo init --name capstone-ext` (binary crate).
`Cargo.toml` deps: `anyhow`, `rmcp` (server + macros), `serde` (derive),
`serde_json`, `tokio`, `tracing`. Reuse your l07 `notes-server` as the
skeleton, then make it *yours* (your tools, your domain).

**B — plugin route:** no Cargo needed for pure skills/hooks; if you ship a
hook script, it still counts as an extension. Use l08/l09's plugin repo but
complete it: real commands, real skills, tested hook logic.

Both routes must still end with the artifact checklist from Step 4.

## Step 3 — Implement with hardening (15 min)

Minimum three tools/commands with real behavior. Apply the Unit 3 discipline:

- typed `Parameters` (JsonSchema) + `INVALID_PARAMS` guards (l07)
- `ErrorData` with actionable messages, `INTERNAL_ERROR` for your faults (l07)
- if hooks: `{"decision":"block"|"allow"}` protocol, exit 0 always (l09)
- auth (if any): env_keys + meta header check (l05/l07)

## Step 4 — Tests (15 min)

1. `tests/integration.rs` — one end-to-end test per tool, in-process, no
   network (call your handler functions directly or serve on
   `rmcp::transport::child_process`-free in-memory duplex — simplest: refactor
   tool bodies into plain async fns and test those, noting the seam in a
   comment).
2. Unit tests for pure validation (`validate_*`) — the l07 pattern.
3. At least one failure-branch test (bad input, timeout, auth rejection).

## Step 5 — Docs + manifest + QA gate (15 min)

1. `README.md` — install (`goose plugin install <url>` for plugins, or
   config.yaml `extensions` entry for servers), configuration table, tools
   table, permissions.
2. Manifest: `plugin.json` (plugin route) or `config.example.yaml`
   (server route) — run the name-rule audit from l01 if plugin route.
3. Run the gates and record an honest report:

```powershell
Set-Location $env:CAPSTONE
# plugin route: replace the cargo commands with your hook/skill validation
"GATE fmt --check START" | Add-Content qa-report.txt -Force
cargo fmt --all -- --check 2>&1 | Add-Content qa-report.txt
"GATE fmt --check END (exit $LASTEXITCODE)" | Add-Content qa-report.txt
cargo test 2>&1 | Tee-Object -FilePath qa-report.txt -Append
cargo clippy --all-targets -- -D warnings 2>&1 | Tee-Object -FilePath qa-report.txt -Append
Add-Content qa-report.txt "CLIPPY-RUN-DONE"
Add-Content qa-report.txt "Capstone artifact check: $((Get-ChildItem -Recurse -File | Measure-Object).Count) files"
```

If clippy reports warnings, fix them (do not paper over with `allow`). For
the plugin route, record your validation outputs (name audit, skill
frontmatter audit, hooks schema check) into `qa-report.txt` and append a
final line `GATES-RUN-DONE`. The report must exist either way and honestly
record whatever gates you ran.

## Verification

```powershell
powershell -File verify.ps1 -LabDir $env:LAB10 -GooseRepo $env:GOOSE_REPO
```

## Homework

- Write `docs\nice-to-have.md`: three post-launch improvements for your
  extension ranked by user benefit.
- Practice the live demo you'll give at the exam: install the extension into
  your goose config and capture a transcript of one real session using it
  (save to `demo.md` — the exam asks for it).