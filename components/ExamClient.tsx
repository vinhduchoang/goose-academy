"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import type { Route } from "next";
import { useProgress } from "@/components/ProgressProvider";
import { Quiz } from "@/components/Quiz";
import { parseVerifyVerdict } from "@/lib/lab";
import { markMiniLab } from "@/lib/progress";
import type { ExamRecord, LessonMeta } from "@/lib/types";

export function ExamClient({
  exam,
  lessons,
}: {
  exam: ExamRecord;
  lessons: LessonMeta[];
}) {
  const { progress, update } = useProgress();
  const eligible = useMemo(
    () =>
      lessons.length > 0 &&
      lessons.every((l) => {
        const lp = progress.lessons[l.id];
        return lp?.labVerified && lp.bestScore >= 80;
      }),
    [progress, lessons]
  );

  const [output, setOutput] = useState(progress.exams[exam.unitSlug]?.miniLabOutput ?? "");
  const [verdict, setVerdict] = useState<{ passed: boolean; found: string[]; missing: string[] } | null>(
    null
  );

  const markers = exam.miniLab.passMarkers;
  const examProgress = progress.exams[exam.unitSlug];

  function runVerdict() {
    const v = parseVerifyVerdict(output, markers);
    update((p) => markMiniLab(p, exam.unitSlug, output, v.passed));
    setVerdict(v);
  }

  if (!eligible) {
    return (
      <div data-testid="exam-locked-page" className="rounded-lg border border-amber-300 bg-amber-50 p-6 dark:border-amber-800 dark:bg-amber-950/40">
        <h1 className="text-xl font-black">{exam.title}</h1>
        <p className="mt-2 text-sm">
          This exam is locked. Complete every unit lesson (lab verified + test ≥ 80) first.
        </p>
        <Link className="mt-3 inline-block text-sm font-semibold text-sky-600 hover:underline dark:text-sky-400" href={`/units/${exam.unitSlug}` as Route}>
          Back to the unit
        </Link>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <p className="text-xs font-semibold tracking-wide text-zinc-500 uppercase">
          Unit {exam.unitIndex} · {exam.questions.length} questions {markers.length > 0 ? "· mini-lab" : ""}
        </p>
        <h1 className="mt-1 text-3xl font-black tracking-tight">{exam.title}</h1>
        <p className="mt-1 text-sm text-zinc-500">
          {examProgress && examProgress.bestScore > 0
            ? `Best score so far: ${examProgress.bestScore}`
            : "First attempt — questions are graded instantly."}
        </p>
      </div>

      <section data-testid="exam-minilab" className="rounded-lg border border-zinc-200 bg-white p-4 dark:border-zinc-700 dark:bg-zinc-900">
        <h2 className="text-lg font-bold">{exam.miniLab.title}</h2>
        <div className="prose prose-zinc dark:prose-invert mt-2 max-w-none text-sm whitespace-pre-wrap">
          {exam.miniLab.instructions}
        </div>
        <pre className="mt-3 max-h-52 overflow-auto rounded bg-zinc-950 p-3 font-mono text-xs text-zinc-100">
          {exam.miniLab.verifyScript}
        </pre>
        <label className="mt-3 block text-sm font-semibold">
          Paste your verify output (auto-graded against required markers):
        </label>
        <textarea
          data-testid="minilab-output"
          value={output}
          onChange={(e) => {
            setOutput(e.target.value);
            setVerdict(null);
          }}
          rows={5}
          className="mt-1 w-full rounded-md border border-zinc-300 bg-white p-3 font-mono text-xs dark:border-zinc-600 dark:bg-zinc-800"
          placeholder="VERIFY PASSED 10/10 …"
        />
        <div className="mt-2 flex items-center gap-3">
          <button
            type="button"
            data-testid="minilab-grade"
            onClick={runVerdict}
            className="rounded-md bg-zinc-800 px-4 py-2 text-sm font-semibold text-white hover:bg-zinc-700 dark:bg-zinc-200 dark:text-zinc-900"
          >
            Auto-grade mini-lab
          </button>
          {(verdict ?? examProgress?.miniLabPassed) && (
            <p
              data-testid="minilab-verdict"
              className={`text-sm font-semibold ${
                (verdict?.passed ?? examProgress?.miniLabPassed)
                  ? "text-emerald-600 dark:text-emerald-400"
                  : "text-amber-600 dark:text-amber-400"
              }`}
            >
              {(verdict?.passed ?? examProgress?.miniLabPassed)
                ? "Mini-lab verdict: PASS"
                : `Mini-lab verdict: FAIL — missing: ${(verdict?.missing ?? []).join(", ") || "n/a"}`}
            </p>
          )}
        </div>
      </section>

      <Quiz items={exam.questions} scopeId={exam.unitSlug} title={exam.title} scope="exam" />
    </div>
  );
}