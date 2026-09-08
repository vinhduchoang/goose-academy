"use client";

import Link from "next/link";
import type { Route } from "next";
import { useProgress } from "@/components/ProgressProvider";
import { unitStats, lessonAccessor } from "@/lib/progress";
import { ProgressRing } from "@/components/ProgressRing";
import type { LessonMeta, UnitMeta } from "@/lib/types";

export function UnitOverviewClient({
  unit,
  lessons,
}: {
  unit: UnitMeta & { lessonCount: number };
  lessons: LessonMeta[];
}) {
  const { progress } = useProgress();
  const stats = unitStats(progress, lessons.map((l) => l.id), unit.slug);

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <p className="text-xs font-semibold tracking-wide text-zinc-500 uppercase">Unit {unit.index}</p>
          <h1 className="mt-1 text-3xl font-black tracking-tight">{unit.title}</h1>
          <p className="mt-2 max-w-xl text-sm text-zinc-600 dark:text-zinc-300">{unit.tagline}</p>
        </div>
        <ProgressRing pct={stats.pct} size={88} stroke={8} />
      </div>

      <section
        data-testid="exam-gate"
        className={`rounded-lg border p-4 ${
          stats.examEligible
            ? "border-emerald-300 bg-emerald-50 dark:border-emerald-800 dark:bg-emerald-950/40"
            : "border-amber-300 bg-amber-50 dark:border-amber-800 dark:bg-amber-950/40"
        }`}
      >
        <p className="font-bold">Unit {unit.index} project-exam</p>
        {stats.examEligible ? (
          <>
            <p className="mt-1 text-sm">
              Every lesson is complete (lab + test ≥ 80). Exam unlocked{stats.examBest > 0 ? ` — best ${stats.examBest}` : ""}.
            </p>
            <Link
              data-testid="exam-link"
              href={`/exam/${unit.slug}` as Route}
              className="mt-3 inline-block rounded-md bg-emerald-600 px-4 py-2 text-sm font-semibold text-white hover:bg-emerald-500"
            >
              Take the exam
            </Link>
          </>
        ) : (
          <p data-testid="exam-locked" className="mt-1 text-sm">
            Locked — finish all {stats.total} lessons (lab verified + test ≥ 80).
            {stats.complete}/{stats.total} done.
          </p>
        )}
      </section>

      <ul className="space-y-2" data-testid="lesson-list">
        {lessons.map((l) => {
          const lp = lessonAccessor(progress, l.id);
          const done = lp.labVerified && lp.bestScore >= 80;
          return (
            <li key={l.id}>
              <Link
                href={`/units/${l.unitSlug}/${l.slug}` as Route}
                className="flex items-center justify-between gap-3 rounded-lg border border-zinc-200 bg-white px-4 py-3 transition hover:border-sky-300 dark:border-zinc-700 dark:bg-zinc-900 dark:hover:border-sky-700"
              >
                <span className="flex items-center gap-3">
                  <span
                    className={`flex h-6 w-6 items-center justify-center rounded-full text-xs font-bold ${
                      done
                        ? "bg-emerald-500 text-white"
                        : "bg-zinc-200 text-zinc-600 dark:bg-zinc-700 dark:text-zinc-300"
                    }`}
                  >
                    {done ? "✓" : l.order}
                  </span>
                  <span className="text-sm font-semibold">{l.title}</span>
                </span>
                <span className="text-xs text-zinc-500">
                  {lp.labVerified ? "lab ✓" : "lab ·"}
                  {" "}
                  {lp.bestScore >= 80 ? `test ${lp.bestScore}` : "test ·"}
                </span>
              </Link>
            </li>
          );
        })}
      </ul>
    </div>
  );
}