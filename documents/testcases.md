# Goose Contributor Academy — Test Inventory

Status: derived from COURSE-PLAN.md §4 (self-verification stack), business-rules.md
(BR ids), usecases.md (UC ids). Traceability rule: UC → TC (here) → test file →
code, implementation per architecture.md lib/ layout.

Every TC below exists (or must exist) at the "Automated check" path. Green gate =
`pnpm typecheck && pnpm test && pnpm verify:content && pnpm test:e2e`.

## Group E2E — Playwright golden flows (`e2e/`)

### TC-E2E-01 — Lesson journey: theory → lab → test → score renders (flow 1)

- **Objective:** full lesson loop renders score end-to-end
- **Maps:** UC-02, UC-03; BR-02
- **Input setup:** fresh LocalStorage, run chromium against `/units/rust-core/01-toolchain`
- **Expected:** Theory tab renders MDX with shiki highlighting; Lab tab shows
  verify.ps1 block; Test tab shows 6-8 items; submit → score screen appears
- **Automated check:** `e2e/flow-01-lesson.spec.ts` (`pnpm test:e2e`)
- **Acceptance criteria:**
  - Theory content visible without client JS errors
  - Test tab item count within [6,8]
  - Score value on screen equals `round(correct/total*100)`

### TC-E2E-02 — Remediation loop + 100 cap (flow 2)

- **Objective:** weak topics → drills → retake until 100, cap honored
- **Maps:** UC-03, UC-04, UC-08; BR-06, BR-10
- **Input setup:** seed progress with one score-60 attempt; complete drill flow; retake with all-correct
- **Expected:** Remediation shows weakest topic first, ≤3 drills per topic, drill
  links open `/drills?topic=`; after all-correct retake score = 100, topic leaves
  remediation, no value > 100 ever rendered
- **Automated check:** `e2e/flow-02-remediation.spec.ts`

### TC-E2E-03 — Exam gating + mini-lab verdict (flow 3)

- **Objective:** gate blocks locked exam; unlocked exam verdict pass/fail behavior
- **Maps:** UC-06, UC-07; BR-05, BR-07
- **Input setup:** two learners states — (a) no completed lessons, (b) all lessons complete
- **Expected:** (a) `/exam/rust-core` blocked with gate message; (b) exam opens,
  pasting output missing one passMarker → verdict "fail" with missing marker
  listed; pasting output containing all markers → "pass"
- **Automated check:** `e2e/flow-03-exam.spec.ts`

### TC-E2E-04 — Dashboard persistence across reload (flow 4)

- **Objective:** LocalStorage progress survives reload, version 1 shape
- **Maps:** UC-01, UC-09; BR-08
- **Input setup:** complete u0-l01 test+labs, assert stored key, reload page
- **Expected:** progress ring on dashboard updates; after `page.reload()` values
  identical (`bestScore`, `labVerified`, attempt count); key is
  `goose-academy.progress.v1`
- **Automated check:** `e2e/flow-04-persistence.spec.ts`

### TC-E2E-05 — Drift checker flags broken citation (flow 5)

- **Objective:** broken file:line cite blocks the gate
- **Maps:** UC-10; BR-09
- **Input setup:** clone content, inject a cite `{file: "Cargo.toml", line: 99999}`
- **Expected:** `pnpm drift` reports the cite with file+line+reason, exit code
  non-zero; fixing the cite restores exit 0
- **Automated check:** `e2e/flow-05-drift.spec.ts` (spawns `pnpm drift`)

### TC-E2E-06 — Unit 0 lesson 1 full smoke (flow 6)

- **Objective:** end-to-end guest onboarding works, no backend
- **Maps:** UC-01, UC-05, UC-02; BR-01, BR-04
- **Input setup:** empty state; journey u0-l01 from dashboard next-up
- **Expected:** dashboard → lesson → theory → lab verify-paste parse shows
  markers → test → score; `labVerified` checkbox state reflected in gating;
  zero network requests to any backend
- **Automated check:** `e2e/flow-06-u0l01-smoke.spec.ts`

## Group GR — grading (`tests/unit/grading.test.ts`)

### TC-GR-01 — Score math

- **Objective:** plain-total score computes correctly
- **Maps:** BR-02; UC-03
- **Input:** 6 items, 5 correct
- **Expected:** score = 83 (round(5/6*100)); with 7/7 → 100
- **Automated check:** `vitest` — `scoreAttempt` cases

### TC-GR-02 — Cap 100 / floor 0

- **Objective:** no over-scoring, no negative
- **Maps:** BR-02, BR-10; UC-03
- **Input:** all-correct array; empty selections
- **Expected:** 100 exactly; 0 (not NaN / negative); any injected ratio >1 returns 100

### TC-GR-03 — Topic aggregation

- **Objective:** per-topic breakdown
- **Maps:** BR-06 (input); UC-04
- **Input:** mixed items across `[cargo, workspace, cargo]` with 1/2 cargo correct
- **Expected:** perTopic = `{cargo: 50, workspace: 100}`

### TC-GR-04 — Pass threshold

- **Objective:** 80 boundary inclusive
- **Maps:** BR-03; UC-06
- **Input:** scores 79, 80, 100
- **Expected:** 79 fail, 80 pass, 100 pass via the single threshold constant

### TC-GR-05 — Unanswered items

- **Objective:** missing selections handled
- **Maps:** BR-02; UC-03
- **Input:** 3 of 4 answered, `selected = null` on last
- **Expected:** unanswered counts incorrect; total still 4 in denominator; no throw

## Group RE — remediation (`tests/unit/remediation.test.ts`)

### TC-RE-01 — Weak ranking weakest-first

- **Maps:** BR-06; UC-04
- **Input:** perTopic `{a: 80, b: 100, c: 20}`
- **Expected:** list `[c, a]`, b excluded (100 = mastered)

### TC-RE-02 — Topic → lesson map

- **Maps:** BR-06; UC-04
- **Input:** manifest with 3 lessons touching `ownership`
- **Expected:** `mapTopicToLessons("ownership")` returns exactly those 3 ids, ordered

### TC-RE-03 — Drill selection ≤3

- **Maps:** BR-06; UC-08
- **Input:** drill bank with 5 `ownership` drills
- **Expected:** `pickDrills("ownership")` returns 3 distinct ids; unknown topic → []

### TC-RE-04 — Retake loop terminates at 100

- **Maps:** BR-06, BR-10; UC-03
- **Input:** simulate attempts 60 → 85 → 100
- **Expected:** loop state machine stops after the 100 attempt; topic removed from weak list

## Group PR — progress (`tests/unit/progress.test.ts`)

### TC-PR-01 — Complete rule

- **Maps:** BR-04; UC-06
- **Input:** `{labVerified: true, bestScore: 80}` and `{true, 79}` and `{false, 100}`
- **Expected:** complete, incomplete, incomplete respectively

### TC-PR-02 — Attempt history + bestScore monotonicity

- **Maps:** BR-04; UC-03
- **Input:** attempts 90 then 70
- **Expected:** bestScore stays 90; attempts array length 2, order preserved

### TC-PR-03 — LocalStorage round-trip

- **Maps:** BR-08; UC-09
- **Input:** save seeded Progress; simulate reload via fresh load(); corrupt /
  `{version: 2}` stub
- **Expected:** round-trip deep-equal; corrupt + wrong-version → fresh empty state, no crash

### TC-PR-04 — Exam gate

- **Maps:** BR-05; UC-06
- **Input:** unit with 15 lessons, 14 complete vs 15 complete
- **Expected:** locked vs unlocked

## Group CS — content schema (`tests/unit/schema.test.ts` + `scripts/verify-content.ts`)

### TC-CS-01 — Item shape

- **Maps:** BR-01; UC-10
- **Input:** item with 3 options / answer 4 / explanation len 2 / topic `nope`
- **Expected:** each variant rejected with field-level error; valid exemplar passes

### TC-CS-02 — Lesson frontmatter

- **Maps:** BR-01; UC-10
- **Input:** lesson.mdx missing `topics`, bad `cites` entry `{file, line:"x"}`
- **Expected:** reject; 8 required keys enforced; cite line must be positive int

### TC-CS-03 — Topics canonical

- **Maps:** BR-01; UC-10
- **Input:** test.json topic `does-not-exist` vs topics.json
- **Expected:** `pnpm verify:content` fails naming file + topic; every authored
  topic across content/ is contained in topics.json

### TC-CS-04 — Exams counts + miniLab

- **Maps:** BR-07; UC-07, UC-10
- **Input:** u0 with 24 questions; u3 with 39; miniLab missing `passMarkers`
- **Expected:** each fails; 25/25/25/40 enforced; passMarkers non-empty string[]

### TC-CS-05 — Drills bank

- **Maps:** BR-06; UC-10, UC-08
- **Input:** drills.json with 15 drills / drill missing `hint`
- **Expected:** ≥16 enforced; missing field rejected

## Group DR — drift (`tests/unit/drift.test.ts`)

### TC-DR-01 — Missing file

- **Maps:** BR-09; UC-10
- **Input:** cite `{file: "no/such.rs", line: 1}` against temp checkout fixture
- **Expected:** `{ok: false, reason: "missing-file"}`

### TC-DR-02 — Line out of range

- **Maps:** BR-09
- **Input:** real 3-line file, cite line 99999
- **Expected:** `{ok: false, reason: "line-out-of-range"}`

### TC-DR-03 — Valid cite

- **Maps:** BR-09
- **Input:** cite matching an actual line in fixture
- **Expected:** `{ok: true}`

### TC-DR-04 — Report + gate blocking

- **Maps:** BR-09; UC-12
- **Input:** bundle of 1 broken + 2 valid cites
- **Expected:** runner returns all broken cites (file:line + reason), exit non-zero; all-valid → exit 0

## Group LB — lab (`tests/unit/lab.test.ts`)

### TC-LB-01 — verify.ps1 generator

- **Maps:** UC-11, UC-05; BR-07 (markers)
- **Input:** `generateVerifyScript("u0-l01", checks)` with 4 checks
- **Expected:** output parses as PowerShell 5.1, contains `param([string]$GooseRepo=...)`,
  `Check` calls with 3 args, `VERIFY PASSED`/`VERIFY FAILED` lines, `exit 0/1` paths

### TC-LB-02 — passMarkers verdict parsing

- **Maps:** BR-07; UC-05, UC-07
- **Input:** pasted output containing 2 of 3 markers; then all 3; case-flipped marker
- **Expected:** fail with missing=[marker3]; pass with missing=[]; case-flipped
  marker does NOT satisfy (case-sensitive)

## Group EX — exam logic (`tests/unit/exam.test.ts`)

### TC-EX-01 — Exam scoring reuses BR-02/BR-03

- **Maps:** BR-02, BR-03; UC-07
- **Input:** 25-item exam, 20 correct
- **Expected:** score 80 → pass (inclusive threshold)

### TC-EX-02 — ExamRecord shape incl. miniLab verdict

- **Maps:** BR-07, BR-08; UC-07
- **Input:** submit exam with verdict pass {passedMarkers:[...], missingMarkers:[]}
- **Expected:** record persists `examId, bestScore, attemptCount≥1, miniLabVerdict`, zod-valid

### TC-EX-03 — Final exam 40 questions spans units

- **Maps:** BR-01; UC-07
- **Input:** load u3 exam
- **Expected:** exactly 40 items; topic set intersects all four units' topic sets

## Inventory summary

- E2E: 6 (TC-E2E-01..06); unit TCs: GR 5, RE 4, PR 4, CS 5, DR 4, LB 2, EX 3 = 27.
- **Total: 33 TCs.** Coverage: every BR (01-10) and every UC (01-12) is referenced
  by at least one TC.