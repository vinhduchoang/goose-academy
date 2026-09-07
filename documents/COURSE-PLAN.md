# Goose Contributor Academy — Course + App Plan

Status: DESIGN LOCKED (2026-09-07). This file is ground truth. Move whole folder to
`C:\Users\admin\projects\goose-academy` after git setup, keeping this filename.

Target learner: FE developer (JS/TS), new to Rust. Goal: read `crates/goose` like a
maintainer, ship core-lib PRs following repo conventions, build production-grade
extensions (providers, MCP tools, plugins).

Pedagogy: 30% theory / 70% practice. Every theory block enables a lab. Labs run
against a local goose clone, pinned to release v1.49.0. All lessons cite real files
with `file:line` where possible.

---

## 1. Course Content

46 lessons, 4 units, 4 project-exams. Each lesson = Theory (<=20 min) -> Lab
(40-50 min, against real repo) -> Homework -> Lesson test -> remediation report ->
retake until 100.

Learning loop:

```
Theory -> Lab -> Homework -> Lesson test -> weak-topic report
-> targeted re-practice -> retake until 100 -> Unit project-exam -> remediation loop
```

### Unit 0 — Rust for Goose (15 lessons + exam)

Capstone (exam mini-lab): build tiny "echo agent" — struct + trait + `anyhow` +
serde struct + async stream + lock-guarded state. Must pass `cargo test` + clippy.

Block A: Syntax & Core (9)

| # | Lesson | Goose-grounded lab |
|---|--------|--------------------|
| 0.1 | Toolchain: rustup, cargo, workspace `crates/*`, Justfile, cargo build/test/clippy/fmt | Build goose; explain workspace `resolver = "2"`, map each crate |
| 0.2 | Data types: scalars (`usize`, `u64`, `f32`, `bool`, `char`), `mut`, shadowing, type inference, `dbg!` | Token-count exercise using `usize`; find inferred-vs-explicit types in `token_counter.rs` |
| 0.3 | Compound types: tuples, arrays, `Vec`, slices, `String` vs `&str` | String ops on prompt text from `prompts/`; fix planted `String`/`&str` mismatches |
| 0.4 | Functions: params, returns, expressions vs statements, block-as-value, early return | Port a small TS helper (e.g. char-truncate) to idiomatic Rust |
| 0.5 | Control flow: `if/else`, `loop`/`while`/`for`, ranges, `break`/`continue`, `iter()` intro | Loop over `Vec<Message>`-like data; convert JS `for...of` mental model |
| 0.6 | `match` and pattern matching intro: `if let`, exhaustive arms | Match on an enum similar to `types.rs` variants; compiler teaches exhaustiveness |
| 0.7 | Ownership: move / copy / clone; why no GC; stack vs heap | Fix move errors in scratch fn; identify `.clone()` sites in goose and explain them |
| 0.8 | References & borrowing: `&`, `&mut`, slices, borrow rules | Write `fn trim_prompt(&str) -> &str`; borrow-checker drills |
| 0.9 | Lifetimes: what/why, elision, explicit `&'a` | Grep lifetimes in `crates/goose/src`; write 2 fns needing explicit annotations |

Block B: Types & Abstraction (3)

| # | Lesson | Goose-grounded lab |
|---|--------|--------------------|
| 0.10 | Structs + `impl`: methods vs associated fns, `pub`/`pub(crate)` visibility | Build a `ModelConfig`-shaped struct with builder-ish helpers |
| 0.11 | Enums with data, `Option`/`Result`, error-as-value | Parse a value chain returning `Result`; exhaustive `match` both arms |
| 0.12 | Generics + traits + built-in derives (`Debug`, `Clone`, `PartialEq`) | Generic `fn summarize<T: Display>`; implement a small trait (preview: exactly how `Provider` works, providers/base.rs) |

Block C: Project-flavored advanced (3)

| # | Lesson | Goose-grounded lab |
|---|--------|--------------------|
| 0.13 | Error handling in practice: `?`, `anyhow::Result`, `thiserror` — AGENTS.md rule: errors use `anyhow::Result` | Refactor scratch crate panic/`unwrap` -> `anyhow` + `?`; compare with goose error style |
| 0.14 | Serde: `#[derive(Serialize, Deserialize)]`, attrs (`rename_all`, `default`) | Round-trip `model_config.rs`-style JSON; add field with backward-compat `default` |
| 0.15 | Shared state + async: `Arc`/`Mutex`/`RwLock`, tokio, `async fn`/`.await`, `async_trait`, `Stream` | Mini fake provider: async fn yielding a message stream like `Provider::complete` |

### Unit 1 — Architecture Mastery (11 + exam)

Goal: navigate, trace, and explain any subsystem like a maintainer. Every module
lesson has a "founder lens" box: What problem it solves -> design tradeoff -> where
it's heading -> where it breaks -> where you'd extend it.

| # | Lesson | Deep-lab |
|---|--------|----------|
| 1.1 | Workspace graph: crate boundaries, dependency direction, why `goose-sdk-types`/`goose-provider-types` exist | Build real graph via `cargo metadata`; explain every arc |
| 1.2 | Core data model: `Message` -> `Reply`/`ReplyPart`/`ToolCall`, `ModelConfig` | Trace creation->consumption path; draw flow diagram |
| 1.3 | Config system: `config/`, profiles, extension config | Change 1 config key, follow it into runtime |
| 1.4 | Agent lifecycle I: entry hooks -> loop -> tools (`agents/agent.rs` legacy) | Add tracing prints; record one turn's event log |
| 1.5 | Agent lifecycle II: state machine as ops + effects (`ops_llm`, `ops_toolcalling`, `effects.rs`) | Map each `ops_*` file to legacy counterpart; find parity gaps |
| 1.6 | Providers deep: `Provider` trait, `complete()`, formats, usage estimation, `canonical_cost` | Read 1 full provider; answer "where would streaming break" |
| 1.7 | Tool pipeline & permissions: dispatch, `tool_confirmation`, `permission/`, `security/` | Instrument a tool call through rejection & auto-approve |
| 1.8 | Extension system: discovery -> `validate_extensions` -> manager -> load | Follow an extension from disk to live tool, step by step |
| 1.9 | MCP internals: `mcp_client.rs`, rmcp, schema normalization | Cross-server schema collision drill |
| 1.10 | Session & context: manager, compaction, `context_limit`, `chat_history_search` | Force a compaction; verify history survives |
| 1.11 | Observability: `tracing/otel`, `doctor.rs`, logging, `gen_ai_telemetry` | Diagnose a seeded production-style incident |

Exam/project: Architecture dossier — 1-page module map + auto-graded trace tasks
(3 "find & explain" prompts, submit file:line answers) + 25 tagged Qs.

### Unit 2 — Core Contribution (10 + exam)

Goal: land first real PR to core the way a maintainer would.

| # | Lesson | Deep-lab |
|---|--------|----------|
| 2.1 | Contribution operations: Ready issues, templates, board rituals | Triage 3 real past issues; write one new issue by template |
| 2.2 | Bug reproduction & bisecting: read issue -> repro -> isolate | Reproduce a seeded bug; bisect to commit |
| 2.3 | Debug kit: `RUST_LOG`, tracing spans, snapshots, `--test-threads` | Debug a failing integration test to root cause |
| 2.4 | Testing doctrine: unit vs `tests/`, `goose-test-support` mock provider, `just record-mcp-tests`, snapshot updates | Write a provider test with mock; record an MCP test |
| 2.5 | Small fix I: clippy cleanups (workspace lint `string_slice`) | Land 3 warning fixes, clippy `-D warnings` green |
| 2.6 | Small fix II: agent-loop bug BOTH paths + regression test | Fix parity bug; prove behavior identical both paths |
| 2.7 | Feature work mini-cycle: proposal -> minimal impl -> tests -> `goose-self-test.yaml` update | Ship tiny real feature end-to-end |
| 2.8 | Self-test & recipes: rebuild, run `goose run --recipe goose-self-test.yaml`, add scenario | Verify feature survives self-test |
| 2.9 | Performance & memory: `context_limit`, `token_counter`, `large_response_handler` | Profile a slow path; make one measurable improvement |
| 2.10 | Review mastery: AGENTS.md rules, deny.toml, planted-bad-diff hunting | Review 2 planted diffs; catch all violations |

Exam/project: Real PR on fork — pick a Ready issue, implement, CI-green, PR
description with verification plan. Auto-grade: fmt + clippy + tests + parity check +
`GOOSE_STATE_MACHINE=1` run.

### Unit 3 — Extension Mastery (10 + final exam)

Goal: build production-grade extensions (provider AND MCP), not toy demos.

| # | Lesson | Deep-lab |
|---|--------|----------|
| 3.1 | Extension anatomy: manifest, discovery, validation pipeline, malware check | Hand-write manifest; pass every validation stage |
| 3.2 | Provider I: echo provider (`complete()`, enclosure types) | Working echo LLM in ~150 lines |
| 3.3 | Provider II: streaming, usage/token accounting, cost, telemetry | Add streaming + accurate usage to provider |
| 3.4 | Provider III: formats (OpenAI/Anthropic envelopes), tool-call mapping | Emit native-format tool calls, round-trip through goose |
| 3.5 | Registration & auth: registry, `provider_secrets`, OAuth flows | Register, configure, secret-manage provider |
| 3.6 | MCP I: `goose-mcp` crate, server example -> tools in goose | MCP server's tools callable from goose live |
| 3.7 | MCP II: schemas, errors, elicitation, auth | Harden server: bad input, timeouts, auth handshake |
| 3.8 | Plugins & skills: plugin with slash commands + `skills/` | Publish installable plugin; pass validation path |
| 3.9 | Advanced: hooks, permission rules, subagents | Extension that uses hooks + asks permission elegantly |
| 3.10 | Capstone: real extension solving YOUR workflow + docs + tests | Complete extension, reviewed end-to-end, publish-ready |

Final exam: Capstone ships green (`cargo test` + clippy on extension crate), live
demo transcript, + 40-Q comprehensive exam across all units.

### Cross-cutting threads (all units)

- Legacy <-> state-machine parity (AGENTS.md rule) — taught as skill, tested in Unit 2 exam.
- Conventions as muscle memory: fmt/clippy/deny.toml/self-test loop.
- Founder lens per module.

---

## 2. Assessment Engine (business rules)

- Lesson test: 6-8 items (MC, "what does this print", "fix this compile error").
  Each item tagged with topics. Wrong-option explanations provided (not just correct answer).
- Unit exam: 20-25 tagged items + auto-graded mini-lab (verify script must pass).
- Score cap: 100. Reaching 100 marks topics mastered; no over-scoring.
- Remediation engine: per-topic % -> weak topics sorted -> map to exact
  lessons/labs to redo + 1-3 drills from a drill bank -> retake loop until 100.
- Progress model: lesson complete = lab passed AND test >= 80.
- Grading = pure TS functions, unit-tested (Vitest).

---

## 3. Web App Architecture

Stack: Next.js (App Router) + MDX + Tailwind + shiki. No backend v1:
static MDX content, LocalStorage progress, client-side grading.
DB (SQLite/Prisma) only if cloud sync needed later — do not add prematurely.

### Directory layout (inside goose-academy)

```
goose-academy/
├─ docs/
│  ├─ architecture.md      # system design, data models, page/component map, content schema
│  ├─ usecases.md          # user stories, numbered UC-xx
│  ├─ business-rules.md    # grading caps, topic rules, thresholds, gating, drift policy
│  ├─ testcases.md         # test inventory TC-xx mapped to tests; acceptance criteria
│  ├─ milestones.md        # sprints w/ acceptance criteria + DoD
│  └─ PROGRESS.md          # live log: decisions, state, issues, resume point
├─ app/                    # Next.js source
├─ content/                # 4 units, 46 lessons
│  └─ units/{unit}/{lesson}/
│     ├─ lesson.mdx        # frontmatter: topics, files[] cited w/ file:line
│     ├─ lab.md
│     ├─ verify.ps1        # per-lab auto-check (PowerShell 5.1 / Windows)
│     └─ test.json
└─ e2e/                    # Playwright specs
```

### Pages

- `/` dashboard: 4 unit cards, progress ring, next-up action
- `/units/[slug]` unit overview + exam gate
- `/units/[slug]/[lesson]` lesson page (Theory / Lab / Test tabs)
- `/exam/[unit]` exam mode
- `/report/[attempt]` score + remediation panel
- `/drills?topic=` drill bank

### Interactive components

`<Diff/>`, `<CodeRunnerPrompt/>`, `<Quiz/>`, `<ScoreBreakdown/>`, `<Remediation/>`,
`<ProgressRing/>`, founder-lens box, FE->Rust mind-shift box.

### Content model

`test.json`: `[{q, options, answer, topic, explanation[]}]` — explanation = array of
reasons per wrong option. Zod-validated at `pnpm verify:content`.

### Booking note

`lesson.mdx` frontmatter must include `unit`, `order`, `topics[]`, `cites[]`
(file:line refs) so lesson spacing/ordering changes never break references.

---

## 4. Self-Verification Stack

Commands (run end-to-end, no human needed):

```
pnpm typecheck && pnpm test && pnpm verify:content && pnpm test:e2e
```

- Vitest (`pnpm test`): grading engine (score math, topic aggregation, 100 cap),
  remediation engine (mapping, retake loop), progress/persistence helpers,
  drift-checker core, content schema validation.
- Playwright (`pnpm test:e2e`): 6 golden flows —
  1. lesson: theory -> lab view -> test -> score renders
  2. remediation loop: weak topic -> suggested drills -> retake -> 100 cap honored
  3. unit exam gating + mini-lab auto-grading verdict
  4. dashboard progress persists across reload (LocalStorage)
  5. drift checker flags broken file:line citation
  6. full Unit 0 lesson 1 journey smoke (guest learner, no backend)

### Self-heal protocol (documented in PROGRESS.md)

1. test fails -> capture repro output -> open docs/testcases.md, find TC id
2. check usecases.md/business-rules.md -> is code or spec wrong? update whichever is wrong
3. fix -> rerun verification gate -> append decision to PROGRESS.md same session

Traceability rule: every UC -> TCs (testcases.md) -> test files -> code.
Nothing ships without both spec and tests updated.

---

## 5. Phases (implementation order)

| Phase | Deliverable | DoD |
|-------|-------------|-----|
| 1 | Next.js scaffold + MDX + Tailwind + shiki + Vitest + Playwright + docs/ skeleton | `pnpm dev` serves; gate skeleton runs |
| 2 | Docs v1: architecture, usecases, business-rules, testcases, milestones | All UCs numbered; TCs have acceptance criteria |
| 3 | Content schema (Zod) + models + grading/remediation pure functions | Vitest green |
| 4 | Quiz + remediation engine UI | flows 1-2 green |
| 5 | Lesson 3-tab layout + lab runner (+ `verify.ps1` generator) | flow 6 green |
| 6 | Dashboard/units/exam pages + LocalStorage persistence | flows 3-4 green |
| 7 | Content authoring Unit 0 -> 1 -> 2 -> 3 (each w/ project-exam content, schema-valid, drift-checked) | `pnpm verify:content` green |
| 8 | Playwright flows 1-6 full green | `pnpm test:e2e` green |
| 9 | Drift checker script + PROGRESS.md final review | flow 5 green |
| 10 | Full-gate run + end-to-end learner walkthrough | gate green; walkthrough logged |

Global DoD: no unmerged code without passing gate; PROGRESS.md updated same session.

---

## 6. Risks / Rollback

- Content drift (goose releases fast): pin lessons to v1.49.0; drift checker
  validates `file:line` citations against checkout; per-release re-check task.
- Rust difficulty cliff for FE brain: Unit 0 grounded in goose examples; exam
  gates prevent Unit 2 confusion.
- App over-engineering: no backend v1; add sync only when real need proven.
- Windows lab environment: labs + verify scripts targeted to PowerShell 5.1 / win32.

---

## 7. Artifact relocation

This folder is a temporary isolated artifact inside the goose repo. Move the whole
folder to `C:\Users\admin\projects\goose-academy` after git setup; remove it from
the goose repo to avoid upstream pollution.