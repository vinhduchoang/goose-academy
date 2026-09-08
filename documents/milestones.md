# Goose Contributor Academy — Milestones

Status: all phases from COURSE-PLAN.md §5 are **DONE** (2026-09-08). Rules verified
against business-rules.md (BR), usecases.md (UC), testcases.md (TC), architecture.md.

## Phases

| # | Deliverable | Status | DoD + artifacts |
|---|---|---|---|
| 1 | Next.js scaffold + MDX + shiki + Vitest + Playwright | **DONE** | `pnpm dev` serves; gate skeleton runs. Next 16.3.4 (App Router, Turbopack), `@next/mdx` + `remark-frontmatter` + `remark-mdx-frontmatter` + `remark-gfm`, shiki async RSC, Tailwind v4, zod v4, Vitest 3, Playwright chromium, tsx; exemplar `u0-l01`; `content/topics.json`; gate scripts wired |
| 2 | Docs v1: architecture, usecases, business-rules, testcases, milestones | **DONE** | UC-01..12 (GWT acceptance criteria), BR-01..10 mapped to UCs, 33 TCs with criteria + file locations — `documents/{architecture,usecases,business-rules,testcases,milestones}.md` |
| 3 | Content schema + models + grading/remediation pure engines | **DONE** | 43 Vitest tests green (TC-GR/RE/PR/CS/DR/LB/EX). Artifacts: `lib/{schema,content-io,fmparse,grading,remediation,progress,lab,drift,build-attempt,types}.ts` + `tests/unit/*.test.ts` |
| 4 | Quiz + remediation engine UI | **DONE** | Playwright flows 1-2 green; `/report/[attempt]`, Quiz, ScoreBreakdown, Remediation components |
| 5 | Lesson 3-tab layout + lab runner (+ verify.ps1 generator) | **DONE** | Flow 6 green; tabs Theory/Lab/Test; LabRunner with copy/download + verify checkbox; VerifyGenerator (client-side script builder, TC-LB-01) |
| 6 | Dashboard / units / exam pages + LocalStorage persistence | **DONE** | Flows 3-4 green; `/` unit cards + ProgressRing + next-up; `/units/[slug]` exam gate; `/exam/[unit]` with auto-graded mini-lab; progress storage v1 |
| 7 | Content authoring Unit 0 → 1 → 2 → 3 | **DONE** | `verify:content` green: 46 lessons (15/11/10/10), 4 exams (25/25/25/40 + mini-labs), 30 drills, 78 canonical topics; manifest codegen committed |
| 8 | Playwright flows 1-6 full green | **DONE** | `pnpm test:e2e` → 9 specs green (TC-E2E-01..06) |
| 9 | Drift checker script + PROGRESS.md final review | **DONE** | Flow 5 green; `scripts/check-drift.ts` + `lib/drift.ts`; 277 citations DRIFT OK vs local goose v1.49.0; PROGRESS.md reviewed same session |
| 10 | Full-gate run + end-to-end learner walkthrough | **DONE** | `pnpm typecheck && pnpm test && pnpm verify:content && pnpm test:e2e` green; learner journey exercised by Playwright (guest learner, dashboard→lesson→lab→test→report→remediation→retake; exam gating + verdict); SSR smoke 200 across all unit/lesson/exam/drill/report routes; PROGRESS.md updated |

## Global DoD

- No unmerged code without passing gate.
- PROGRESS.md updated same session.
- On gate failure: TC id → UC/BR → spec-vs-code call → fix → rerun.
- Traceability intact: UC → TC → test file → code.

## Test location map (see testcases.md for criteria)

- Unit: `tests/unit/grading.test.ts` (GR), `remediation.test.ts` (RE),
  `progress.test.ts` (PR), `schema.test.ts` (CS), `drift.test.ts` (DR),
  `lab.test.ts` (LB), `exam.test.ts` (EX)
- E2E: `e2e/flow-{01..06}-*.spec.ts`
- Scripts: `scripts/verify-content.ts`, `scripts/check-drift.ts`,
  `scripts/generate-manifest.ts`

## Ops notes

- `pnpm test:e2e` expects a build to exist (`pnpm build` first) — webServer runs
  `pnpm start`; documented so CI can add a build step if repo goes remote.
- Content edits → `pnpm verify:content` (auto-regenerates `content/manifest.ts`)
  → `pnpm drift C:\Users\admin\projects\goose`.