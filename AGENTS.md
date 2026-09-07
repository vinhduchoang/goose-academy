# Goose Contributor Academy — Agent Guide

## Ground truth

- `documents/COURSE-PLAN.md` — design lock, all product/architecture decisions. Read first.
- `documents/PROGRESS.md` — live state log. Update it **same session** whenever a decision is made, a doc changes, or phase work finishes. Resume point lives here.

Repo is a fresh project: design docs only, **no code yet**. Phase 1 (Next.js scaffold) not started.

## Locked decisions (do not re-litigate)

- Course: 46 lessons, 4 units, 4 exams. Labs run against a **local goose clone pinned to release v1.49.0** (path TBD). Lesson content must cite real files as `file:line`.
- App v1: Next.js App Router + MDX + Tailwind + shiki. **No backend** — LocalStorage progress, client-side grading. No DB/Prisma unless cloud sync proven needed.
- Grading = pure TS functions (Vitest), score cap 100, topic-tagged tests, remediation loop.
- Docs-first + traceability: every UC → TC (`docs/testcases.md`) → test file → code. Nothing ships without spec and tests updated.

## Docs-first workflow

- Architecture/feature docs are the **source of truth**: write them first, verify them, then code against them.
- During development, keep docs current — update `AGENTS.md`, `.agents/rules/`, and feature/architecture docs whenever they need it, same session.

## Verification gate (end to end, no human needed)

```
pnpm typecheck && pnpm test && pnpm verify:content && pnpm test:e2e
```

Global DoD: no unmerged code without passing gate; PROGRESS.md updated same session.

Commit after finishing a step (working change + its docs/tests), so each commit is reviewable in isolation.

## Version-pinned stack knowledge

After any dependency is locked in `package.json`, source its official docs for the
locked version and encode best practice as a repo rule/skill in `.agents/rules/`
and `.agents/skills/` (one per tech stack). This is what agents follow when
writing code for that stack.

Rule files must be written from the *official docs of the locked version* — never
from generic model knowledge or blogs. Stale rule = worse than no rule; re-source
on every version bump.

Code written under these rules must be: best practice, performant, secure, well
structured, no stale/dead code, no duplication, easy to maintain and extend.

## Fixing a failing test (self-heal protocol)

1. Capture repro output → find TC id in `docs/testcases.md`
2. Check `docs/usecases.md` / `docs/business-rules.md` — decide if code or spec is wrong, fix whichever
3. Rerun gate, append decision to PROGRESS.md same session

## Environment

- Windows, PowerShell 5.1. Per-lab verification scripts (`verify.ps1`) target this.