"use client";

import Link from "next/link";
import type { Route } from "next";
import { useProgress } from "@/components/ProgressProvider";
import { ProgressRing } from "@/components/ProgressRing";
import { lessonIsComplete, unitStats } from "@/lib/progress";
import type { LessonMeta, UnitMeta } from "@/lib/types";

export function DashboardClient({
  units,
  lessons,
}: {
  units: (UnitMeta & { lessonCount: number })[];
  lessons: LessonMeta[];
}) {
  const { progress, ready, reset } = useProgress();

  const byUnit = new Map<string, LessonMeta[]>();
  for (const l of lessons) {
    const arr = byUnit.get(l.unitSlug) ?? [];
    arr.push(l);
    byUnit.set(l.unitSlug, arr);
  }

  const stats = units.map((u) => ({
    unit: u,
    ...unitStats(progress, (byUnit.get(u.slug) ?? []).map((l) => l.id), u.slug),
  }));

  const overallComplete = stats.reduce((acc, s) => acc + s.complete, 0);
  const overallTotal = stats.reduce((acc, s) => acc + s.total, 0);
  const overallPct = overallTotal === 0 ? 0 : Math.round((overallComplete / overallTotal) * 100);

  const nextUp = lessons.find((l) => !lessonIsComplete(progress, l.id));

  return (
    <div className="space-y-8">
      <section className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-black tracking-tight">Goose Contributor Academy</h1>
          <p className="mt-2 max-w-xl text-sm text-zinc-600 dark:text-zinc-300">
            46 lessons · 4 units · 4 project-exams. Read goose like a maintainer, land core PRs,
            ship production-grade extensions. All progress lives in this browser.
          </p>
        </div>
        <div className="flex items-center gap-6">
          <ProgressRing pct={overallPct} size={88} stroke={8} label={`${overallPct}%`} />
          <button
            type="button"
            data-testid="reset-progress"
            onClick={() => {
              if (window.confirm("Reset all lesson, lab and exam progress? This cannot be undone.")) {
                reset();
              }
            }}
            className="rounded-md border border-zinc-300 px-3 py-1.5 text-xs text-zinc-500 hover:bg-zinc-100 dark:border-zinc-600 dark:hover:bg-zinc-800"
          >
            Reset progress
          </button>
        </div>
      </section>

      {ready && nextUp && (
        <section data-testid="next-up" className="rounded-lg border border-sky-200 bg-sky-50 p-4 dark:border-sky-900 dark:bg-sky-950/40">
          <p className="text-xs font-semibold tracking-wide text-sky-700 uppercase dark:text-sky-400">Next up</p>
          <Link className="mt-1 block text-lg font-bold text-sky-800 hover:underline dark:text-sky-200" href={`/units/${nextUp.unitSlug}/${nextUp.slug}` as Route}>
            {nextUp.title}
          </Link>
          <p className="text-sm text-sky-700/80 dark:text-sky-300/80">Unit {nextUp.unitIndex} · lesson {nextUp.order}</p>
        </section>
      )}

      <section className="grid grid-cols-1 gap-4 sm:grid-cols-2" data-testid="unit-cards">
        {stats.map(({ unit, pct, complete, total, examEligible, examBest }) => (
          <Link
            key={unit.slug}
            href={`/units/${unit.slug}` as Route}
            className="group rounded-xl border border-zinc-200 bg-white p-5 transition hover:border-sky-300 hover:shadow-md dark:border-zinc-700 dark:bg-zinc-900 dark:hover:border-sky-700"
          >
            <div className="flex items-start justify-between">
              <div>
                <p className="text-xs font-semibold text-zinc-400 uppercase">Unit {unit.index}</p>
                <h2 className="mt-1 text-xl font-bold group-hover:text-sky-600 dark:group-hover:text-sky-400">
                  {unit.title}
                </h2>
                <p className="mt-1 text-sm text-zinc-600 dark:text-zinc-300">{unit.tagline}</p>
              </div>
              <ProgressRing pct={pct} />
            </div>
            <p className="mt-3 text-xs text-zinc-500">
              {complete}/{total} lessons complete
              {examEligible && examBest > 0 && <span className="ml-2">· exam {examBest}</span>}
              {examEligible && examBest === 0 && <span className="ml-2 text-emerald-600 dark:text-emerald-400">· exam unlocked</span>}
              {!examEligible && <span className="ml-2 text-amber-600 dark:text-amber-400">· exam locked</span>}
            </p>
          </Link>
        ))}
      </section>
    </div>
  );
}