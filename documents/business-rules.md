# Goose Contributor Academy — Business Rules (normative)

Status: implements Assessment Engine (COURSE-PLAN.md §2) + content rules
(CONTENT-GUIDE.md). Consumed by usecases.md (UC ids), verified by testcases.md
(TC ids), implemented in `lib/` per architecture.md. Where spec and implementation
disagree, fix whichever is wrong (UC-12), then log in PROGRESS.md.

## Rules

### BR-01 — Lesson test shape (6-8 items, canonical topics)

Lesson test.json = array of 6-8 items. Each item: `options` exactly 4 strings,
`answer` int in [0,3], `topic` ∈ content/topics.json verbatim, `explanation`:
one entry per WRONG option in option order. At least one "fix this compile
error / which change unblocks this" item per lesson.

- **Serves:** UC-03, UC-07, UC-10 (validation). **Tests:** TC-CS-01, TC-CS-02.
- **Content check:** zod `TestItemSchema` in lib/schema.ts.

### BR-02 — Grading math

`score = round(correct / total * 100)`. Cap at 100, floor at 0. Unanswered items
count as incorrect (correct=false, selected=null) and do not divide-by-zero:
empty submission → score 0. Rounding: IEEE round-half-up on the unrounded ratio*100.

- **Serves:** UC-03, UC-07. **Tests:** TC-GR-01, TC-GR-02, TC-GR-05.

### BR-03 — Pass threshold 80

Pass = score >= 80. Applies identically to lesson tests and unit/final exams. The
threshold lives in one constant in `lib/grading.ts`.

- **Serves:** UC-06, UC-07. **Tests:** TC-GR-04.

### BR-04 — Lesson completion + bestScore monotonicity

`isLessonComplete(lessonProgress)` = `labVerified AND bestScore >= 80`. `bestScore`
= max over all recorded attempts; a lower retake NEVER lowers bestScore (no score
regression). `labVerified` is set only by the learner (UC-05) — the app never
auto-sets it; pasted lab output is advisory display only.

- **Serves:** UC-05, UC-06. **Tests:** TC-PR-01, TC-PR-02.

### BR-05 — Exam gate

`isUnitExamUnlocked(unit)` = every lesson in the unit is complete (BR-04). Exam
routes and exam launch UI deny access otherwise.

- **Serves:** UC-06, UC-07. **Tests:** TC-PR-04.

### BR-06 — Remediation

From an attempt: aggregate per-topic % correct; topics below mastery sorted
weakest-first; for each weak topic map to every lesson whose `topics[]` includes
it, plus 1-3 drills (strict max 3) whose `topic` matches, from content/drills.json.
Render retake CTA; the loop repeats until the lesson score reaches 100.

- **Serves:** UC-04, UC-08. **Tests:** TC-RE-01..04.

### BR-07 — Exam mini-lab verdict

`parseVerdict(pastedOutput, passMarkers)`: verdict = "pass" iff pasted text
contains EVERY string in `passMarkers` as a case-sensitive substring.
Verdict (with passed/missing marker lists) is stored IN the ExamRecord and shown
on the exam report; a failed verdict does not block score recording but is
visible in the record.

- **Serves:** UC-07, UC-05 (marker parse reused), UC-11 (markers authored in exam
  json). **Tests:** TC-LB-02, TC-EX-02.

### BR-08 — Progress model (storage shape + version)

Persistence key: `goose-academy.progress.v1` in localStorage. Shape = Progress
(architecture.md §5): `{version: 1, lessons: Record<LessonId, LessonProgress>,
exams: Record<ExamId, ExamRecord>}`. Any stored data with `version != 1` or that
fails the zod Progress schema is discarded (fresh state) — never migrated
silently, never crash.

- **Serves:** UC-09, UC-01, UC-07. **Tests:** TC-PR-03.

### BR-09 — Drift policy

Content cites pinned to goose **v1.49.0** (`C:\Users\admin\projects\goose`,
override via `GOOSE_REPO`). Drift checker (`scripts/check-drift.ts`, core in
lib/drift.ts) verifies every `file:line` cite (file exists, line in range,
optionally content note). Run per lesson authoring and per goose release; any
broken cite fails the verification gate — broken cites block release.

- **Serves:** UC-10, UC-02, UC-12. **Tests:** TC-DR-01..04.

### BR-10 — Mastery themes

- Retake until 100: lesson loop does not end at pass; 100 ends it.
- No over-scoring: 100 is the ceiling (BR-02) — no bonus points, no weighting.
- Topics mastered at 100: a topic counts mastered only when the learner reached
  score 100 on a test covering it; mastered topics leave the remediation list.

- **Serves:** UC-03, UC-08. **Tests:** TC-GR-02, TC-RE-04, TC-E2E-02.

## Rule → UC map (summary)

| BR | UCs served | Primary TC group |
|---|---|---|
| BR-01 | UC-03, UC-07, UC-10 | CS |
| BR-02 | UC-03, UC-07 | GR |
| BR-03 | UC-06, UC-07 | GR |
| BR-04 | UC-05, UC-06 | PR |
| BR-05 | UC-06, UC-07 | PR |
| BR-06 | UC-04, UC-08 | RE |
| BR-07 | UC-07, UC-05, UC-11 | LB, EX |
| BR-08 | UC-09, UC-01, UC-07 | PR |
| BR-09 | UC-10, UC-02, UC-12 | DR |
| BR-10 | UC-03, UC-08 | GR, RE, E2E |