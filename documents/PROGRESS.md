# Goose Contributor Academy — Progress Log

## State

- DESIGN LOCKED: 2026-09-07 (see COURSE-PLAN.md, ground truth).
- Current location: `C:\Users\admin\projects\goose\goose-academy-artifact` (temporary
  isolated folder inside goose repo — do not commit to upstream goose).
- Next action (external): create `C:\Users\admin\projects\goose-academy`, git init,
  move this folder's contents there. Then delete this folder from the goose repo.

## Decisions (locked)

1. Course: 46 lessons, 4 units, 4 project-exams. Unit 0=15 (Rust), 1=11 (architecture),
   2=10 (contribution), 3=10 (extensions).
2. Pedagogy: 30/70 theory-practice. Labs against local goose clone pinned v1.49.0.
3. App: Next.js + MDX + Tailwind + shiki, LocalStorage, no backend v1.
4. Grading: pure TS functions; score cap 100; topic-tagged tests; remediation engine.
5. Docs-first: docs/ = architecture, usecases, business-rules, testcases, milestones,
   PROGRESS. Traceability: UC -> TC -> test -> code.
6. Verification gate: `pnpm typecheck && pnpm test && pnpm verify:content && pnpm test:e2e`.
7. Self-heal protocol adopted (see COURSE-PLAN.md section 4).

## Open items

- Repo location for app (waiting on user to create goose-academy folder).
- No code written yet. Phase 1 not started.

## Resume point (for a fresh session)

1. Read COURSE-PLAN.md fully.
2. Confirm final app location; if still pending, continue in current artifact folder.
3. Start Phase 1: scaffold Next.js + MDX + Vitest + Playwright + docs/ skeleton.
4. Update this file as work progresses (protocol: same-session updates).

## Log

- 2026-09-07: Design created, iterated (Unit 0 expanded to 15 lessons; Units 1-3
  deepened to founder-level). Artifact files written.
- 2026-09-08 (session 1): Phase 1 scaffold. Next.js 16.3.4 (App Router, Turbopack),
  MDX via @next/mdx + remark-mdx-frontmatter (frontmatter YAML -> `frontmatter`
  export), shiki async RSC code highlighting, Tailwind v4 + typography, Vitest 3,
  Playwright (chromium installed), tsx scripts, zod. pnpm 12.3.4 enabled via corepack.
  Exemplar lesson u0-l01 authored (content/units/u0/l01/*) with cites validated
  against local clone (ver 1.49.0). Gate scripts wired in package.json.
  Decisions: lesson route `/units/{unitSlug}/{lessonSlug}`; content ids `un-lnn`;
  `content/manifest.ts` will be codegen (scripts/generate-manifest.ts); drift checker
  accepts GOOSE_REPO path env (local clone C:\Users\admin\projects\goose is v1.49.0).