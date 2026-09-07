# Goose Contributor Academy — Milestones

Status: sprint plan from COURSE-PLAN.md §5, updated with ACTUAL status from
PROGRESS.md. Rules verified against business-rules.md (BR), usecases.md (UC),
testcases.md (TC), architecture.md (lib/ + scripts/ layout).

**Sprint order note (current):** Phase 2 (docs, this task) finishes now; from
there work proceeds IN PARALLEL across three tracks — (a) content authoring
(Phase 7), (b) engines + unit tests (Phase 3), (c) remaining docs updates —
because docs/engines/content share no blocking dependencies except the schema
(Phase 3 first). UI (Phases 4-6) starts after Phase 3 lands.

## Phases

| # | Deliverable | Status | DoD + artifacts |
|---|---|---|---|
| 1 | Next.js scaffold + MDX + shiki + Vitest + Playwright | **DONE** | `pnpm dev` serves; gate skeleton runs. Artifacts: Next 16.3.4 (App Router, Turbopack), `@next/mdx` + `remark-mdx-frontmatter` + `remark-gfm`, shiki async RSC, Tailwind v4, zod v4, Vitest 3, Playwright (chromium installed), tsx; `mdx-components.tsx`, `mdx-frontmatter.d.ts`; exemplar content `u0-l01` (lesson.mdx / lab.md / test.json / verify.ps1, cites validated vs v1.49.0 clone); `content/topics.json`; package.json scripts wired (dev/build/typecheck/test/verify:content/drift/test:e2e); pnpm 12.3.4 |
| 2 | Docs v1: architecture, usecases, business-rules, testcases, milestones | **IN PROGRESS → DONE this sprint** | All 12 UCs numbered with GWT acceptance criteria; 10 BRs map to UCs; 33 TCs have acceptance criteria + file locations. Artifacts: `documents/architecture.md`, `usecases.md`, `business-rules.md`, `testcases.md`, `milestones.md` |
| 3 | Content schema + models + grading/remediation pure engines | PLANNED | `pnpm test` green for TC-GR-*, TC-RE-*, TC-PR-*, TC-CS-01, TC-LB-02 core. Artifacts: `lib/schema.ts`, `content-io.ts`, `grading.ts`, `remediation.ts`, `progress.ts`, `lab.ts`, `tests/unit/{grading,remediation,progress,schema,lab}.test.ts` |
| 4 | Quiz + remediation engine UI | PLANNED | Playwright flows 1-2 green; report page linked. Artifacts: `Quiz`, `ScoreBreakdown`, `Remediation` components; `/report/[attempt]` |
| 5 | Lesson 3-tab layout + lab runner (+ verify.ps1 generator) | PLANNED | Flow 6 green. Artifacts: tabs (Theory/Lab/Test), `LabRunner`; generator in `lib/lab.ts` tested by TC-LB-01 |
| 6 | Dashboard / units / exam pages + LocalStorage persistence | PLANNED | Flows 3-4 green. Artifacts: `/` (4 cards + ProgressRing + next-up), `/units/[slug]` gates, `/exam/[unit]` mini-lab paste, `lib/progress.ts` storage v1 (BR-08) |
| 7 | Content authoring Unit 0 → 1 → 2 → 3 | PLANNED (PARALLEL with 3+ once schema lands) | `pnpm verify:content` green for all 46 lessons + 4 exams + drills. Artifacts: `content/units/u{0-3}/l*` complete per CONTENT-GUIDE.md; `drills.json` ≥16; exams 25/25/25/40; `content/manifest.ts` regenerated via `scripts/generate-manifest.ts` |
| 8 | Playwright flows 1-6 full green | PLANNED | `pnpm test:e2e` green (TC-E2E-01..06). Artifacts: `e2e/*.spec.ts` six flows |
| 9 | Drift checker script + PROGRESS.md final review | PLANNED | Flow 5 green (TC-DR-01..04 + TC-E2E-05); drift core in `lib/drift.ts` behind `scripts/check-drift.ts`, `GOOSE_REPO` env honored, pinned v1.49.0 |
| 10 | Full-gate run + end-to-end learner walkthrough | PLANNED | `pnpm typecheck && pnpm test && pnpm verify:content && pnpm test:e2e` fully green; walkthrough logged in PROGRESS.md same session; TC map complete (all 33 TCs passing or honestly waived w/ reason) |

## Global DoD (every phase)

- No unmerged code without passing gate (COURSE-PLAN.md §4).
- PROGRESS.md updated same session (UC-12 protocol).
- On gate failure: TC id → UC/BR → spec-vs-code call → fix → rerun (UC-12).
- Traceability intact: UC → TC → test file → code (architecture.md §9).

## Test location map (see testcases.md for criteria)

- Unit: `tests/unit/grading.test.ts` (GR), `remediation.test.ts` (RE),
  `progress.test.ts` (PR), `schema.test.ts` (CS core), `drift.test.ts` (DR),
  `lab.test.ts` (LB), `exam.test.ts` (EX)
- E2E: `e2e/flow-{01..06}-*.spec.ts`
- Scripts: `scripts/verify-content.ts`, `scripts/check-drift.ts`,
  `scripts/generate-manifest.ts`