<!-- BEGIN:nextjs-agent-rules -->

# This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` (resolved from this file's directory; in monorepos the `next` package may not be visible from the repo root) before writing any code. Heed deprecation notices.

This block is written and re-added by `next dev` — verify at `node_modules/next/dist/server/lib/generate-agent-files.js`. Removing it from a diff only re-creates the uncommitted change; committing it with your work keeps the tree clean.

<!-- END:nextjs-agent-rules -->

# Goose Contributor Academy — project workflow

Ground truth: `documents/COURSE-PLAN.md` (locked design), `documents/PROGRESS.md`
(live log), `documents/CONTENT-GUIDE.md` (content authoring contract),
`documents/business-rules.md` (grading rules).

## Verification gate (always run before finishing work)

```
pnpm typecheck && pnpm test && pnpm verify:content && pnpm test:e2e
```

- `pnpm test:e2e` needs a fresh build: run `pnpm build` first (webServer runs `pnpm start`).
- Content edits: `pnpm verify:content` auto-regenerates `content/manifest.ts` —
  commit it with your change.
- File:line citations in lessons must stay green against the pinned checkout:
  `pnpm drift C:\Users\admin\projects\goose` (v1.49.0).
- Self-heal protocol: failing test → find TC in `documents/testcases.md` → decide
  code-vs-spec → fix → rerun gate → note decision in PROGRESS.md same session.

## Rules

- Grading is pure TS in `lib/` — UI never recomputes scores; cap 100, threshold 80.
- Lesson complete = lab verified AND best test score ≥ 80 (LocalStorage only, no backend).
- `content/manifest.ts` is codegen — never hand-edit.
- Windows-only surface: verify.ps1 labs are PowerShell 5.1; keep that compatibility.
