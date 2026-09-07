# Goose Contributor Academy — Use Cases

Status: derived from COURSE-PLAN.md (ground truth) §1-4 and CONTENT-GUIDE.md.
Implements business-rules.md (BR ids below); verified by testcases.md (TC ids).
architecture.md documents the system these run on.

Actor baseline: **Guest learner** — FE developer, Windows, PowerShell 5.1, local
goose clone pinned v1.49.0 at `$env:GOOSE_REPO`. No auth, no backend.

Priority scale: P0 = launch-blocking, P1 = core learning loop, P2 = supporting.

---

## UC-01 — Learner lands on dashboard

- **Actor:** Guest learner. **Priority:** P0.
- **GIVEN** the learner opens `/` with no prior progress
- **WHEN** the dashboard renders
- **THEN** 4 unit cards render (Unit 0 Rust for Goose, Unit 1 Architecture Mastery,
  Unit 2 Core Contribution, Unit 3 Extension Mastery), each shows a ProgressRing
  (0% first visit), and a next-up action points at `u0-l01`
- Serves BR-08; verified by TC-E2E-04, TC-E2E-06.

## UC-02 — Learner reads lesson theory

- **Actor:** Guest learner. **Priority:** P0.
- **GIVEN** the learner navigates to `/units/rust-core/01-toolchain`
- **WHEN** the lesson page renders with Theory / Lab / Test tabs
- **THEN** Theory tab shows the MDX body (<=20 min read) with working `Diff`,
  `CodeRunnerPrompt`, `FounderLens`, `MindShift` components, syntax-highlighted
  code via shiki, and inline `file:line` citations as required by BR-09
- Serves BR-01 (items sit in the Test tab, tagged); verified by TC-E2E-01.

## UC-03 — Learner takes lesson test, gets score + remediation, retakes to 100

- **Actor:** Guest learner. **Priority:** P0.
- **GIVEN** learner opens Test tab of a lesson (6-8 items, topic-tagged, BR-01)
- **WHEN** learner answers and submits
- **THEN** `score = round(correct/total*100)` (BR-02) renders via ScoreBreakdown,
  `/report/[attempt]` shows per-topic breakdown + Remediation panel (UC-04), and a
  retake CTA; retaking updates `bestScore` upward only (never regresses, BR-04)
  until 100 is reached (BR-10)
- Verified by TC-GR-01..05, TC-RE-xx via TC-E2E-01, TC-E2E-02.

## UC-04 — Remediation maps weak topics to actionable practice

- **Actor:** Guest learner. **Priority:** P1.
- **GIVEN** a completed attempt with weak topics (per-topic % < 100)
- **WHEN** report renders the Remediation panel
- **THEN** weak topics are sorted weakest-first (BR-06), each maps to the
  lesson(s) touching that topic plus 1-3 drills from the drill bank (max 3, BR-06),
  and every lesson/drill link is actionable (routes resolve)
- Verified by TC-RE-01..04 and TC-E2E-02.

## UC-05 — Learner runs lab verify.ps1 locally, marks lab verified in app

- **Actor:** Guest learner. **Priority:** P0.
- **GIVEN** Lab tab of a lesson showing `lab.md` and its `verify.ps1`
- **WHEN** learner runs `powershell -File verify.ps1` in their shell and then
  (a) ticks the lab-verified checkbox, optionally (b) pastes the output
- **THEN** `VERIFY PASSED`/`VERIFY FAILED` markers parse into the panel (lib/lab),
  `labVerified` lands in LessonProgress (BR-04), and completed labs feed UC-06
  gating
- Verified by TC-LB-01, TC-LB-02, TC-PR-01, TC-E2E-06.

## UC-06 — Completion + exam gating

- **Actor:** Guest learner. **Priority:** P0.
- **GIVEN** any stale lesson progress in a unit
- **WHEN** learner opens `/units/[slug]` or tries `/exam/[unit]`
- **THEN** a lesson counts complete iff `labVerified AND bestScore >= 80` (BR-04),
  next-up points at the first incomplete lesson, and the unit exam unlocks only
  when every lesson in the unit is complete (BR-05)
- Verified by TC-PR-01, TC-PR-03, TC-PR-04, TC-E2E-03.

## UC-07 — Learner takes unit exam incl. mini-lab auto-grading

- **Actor:** Guest learner. **Priority:** P0.
- **GIVEN** an unlocked `/exam/[unit]` (u0-u2: 25 Qs; u3 final: 40 Qs spanning all
  units)
- **WHEN** learner answers all questions, completes the mini-lab locally, pastes
  its output
- **THEN** the exam auto-grades questions (BR-02, threshold 80 per BR-03) and the
  mini-lab verdict passes iff pasted output contains ALL `passMarkers` as
  case-sensitive substrings (BR-07); verdict + score + attemptCount persist to an
  ExamRecord (BR-08)
- Verified by TC-EX-01..03, TC-LB-02, TC-E2E-03.

## UC-08 — Learner drills weak topics

- **Actor:** Guest learner. **Priority:** P1.
- **GIVEN** a remediation link or direct visit to `/drills?topic=ownership`
- **WHEN** the drills page renders
- **THEN** only drills for that canonical topic show (typed bank from
  content/drills.json, >=16 drills), each drill renders id/title/prompt/hint, and a
  topic-less visit lists the bank grouped by topic
- Serves BR-06 loop; verified by TC-RE-03, TC-E2E-02.

## UC-09 — Progress persists in LocalStorage across reloads

- **Actor:** Guest learner. **Priority:** P0.
- **GIVEN** completed attempt(s), lab marks, exam records
- **WHEN** learner reloads or revisits any page
- **THEN** progress loads from `localStorage` key `goose-academy.progress.v1`
  (version 1), bestScores/history/verdicts round-trip losslessly (BR-08), corrupt
  or old-shape data is ignored (fresh state), and no network/backend exists in v1
- Verified by TC-PR-03, TC-E2E-04.

## UC-10 — Content integrity validation

- **Actor:** Maintainer (author/CI). **Priority:** P0.
- **GIVEN** the content tree (units, exams, drills, topics)
- **WHEN** `pnpm verify:content` runs
- **THEN** every schema rule from CONTENT-GUIDE.md is zod-checked (frontmatter keys,
  4 options, answer 0-3, explanation length 3, canonical topics, question counts
  25/25/25/40, drill count >= 16) and problems exit non-zero with file-level errors
  (BR-10 content side); the drift checker (UC-10 extends to BR-09) flags any
  `file:line` cite broken against the pinned v1.49.0 checkout
- Verified by TC-CS-01..05, TC-DR-01..04.

## UC-11 — Authoring tooling

- **Actor:** Content author. **Priority:** P1.
- **GIVEN** a new lesson id + lab checks
- **WHEN** the author uses the verify.ps1 generator (`lib/lab.ts`) and the schema
  doc (CONTENT-GUIDE.md)
- **THEN** a PowerShell 5.1 `verify.ps1` matching the u0-l01 exemplar is produced
  (`param([string]$GooseRepo)`, `Check` helper, `[PASS]/[FAIL]` lines, `VERIFY
  PASSED n/n` + exit 0 / `VERIFY FAILED` + exit 1, 4-7 checks) and re-generating
  `content/manifest.ts` is a one-command step (scripts/generate-manifest.ts)
- Verified by TC-LB-01.

## UC-12 — Self-heal protocol on failing gate

- **Actor:** Maintainer. **Priority:** P2.
- **GIVEN** any failing command in the verification gate
- **WHEN** the self-heal protocol runs (COURSE-PLAN.md §4)
- **THEN** repro output is captured, the TC id is found in testcases.md, the
  relevant UC/BR is checked to decide spec-vs-code, the wrong side is fixed, the
  gate reruns to green, and the decision is appended to PROGRESS.md the same
  session (BR-09 gate rule incl.)
- Verified by TC-E2E-05 workflow in practice; documented in milestones.md.

---

## Traceability matrix

| UC | Priority | BRs | TCs |
|---|---|---|---|
| UC-01 | P0 | BR-08, BR-10 | TC-E2E-04, TC-E2E-06 |
| UC-02 | P0 | BR-01, BR-09 | TC-E2E-01 |
| UC-03 | P0 | BR-01, BR-02, BR-03, BR-10 | TC-GR-01..05, TC-E2E-01, TC-E2E-02 |
| UC-04 | P1 | BR-06 | TC-RE-01..04, TC-E2E-02 |
| UC-05 | P0 | BR-04, BR-07 | TC-LB-01, TC-LB-02, TC-PR-01, TC-E2E-06 |
| UC-06 | P0 | BR-04, BR-05 | TC-PR-01, TC-PR-03, TC-PR-04, TC-E2E-03 |
| UC-07 | P0 | BR-02, BR-03, BR-07, BR-08 | TC-EX-01..03, TC-LB-02, TC-E2E-03 |
| UC-08 | P1 | BR-06 | TC-RE-03, TC-E2E-02 |
| UC-09 | P0 | BR-08 | TC-PR-03, TC-E2E-04 |
| UC-10 | P0 | BR-01, BR-09 | TC-CS-01..05, TC-DR-01..04 |
| UC-11 | P1 | BR-07 | TC-LB-01 |
| UC-12 | P2 | BR-09 | TC-CS-xx reruns, gate |