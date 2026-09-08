"use client";

import Link from "next/link";
import type { Route } from "next";
import type { Attempt, Drill, TopicLessonsIndex } from "@/lib/types";
import { remediationPlan } from "@/lib/remediation";

export function Remediation({
  attempt,
  index,
  drills,
}: {
  attempt: Attempt;
  index: TopicLessonsIndex;
  drills: Drill[];
}) {
  if (attempt.score >= 100) {
    return (
      <section data-testid="remediation-done" className="rounded-lg border border-emerald-300 bg-emerald-50 p-4 dark:border-emerald-800 dark:bg-emerald-950/40">
        <p className="font-semibold text-emerald-800 dark:text-emerald-300">
          All topics mastered — score capped at 100. Move on.
        </p>
      </section>
    );
  }
  const plan = remediationPlan({ byTopic: attempt.byTopic }, index, drills);
  return (
    <section data-testid="remediation-panel" className="space-y-4">
      <h2 className="text-lg font-bold">Remediation plan</h2>
      {plan.steps.length === 0 && (
        <p className="text-sm text-zinc-600 dark:text-zinc-400">Nothing weak — nice.</p>
      )}
      {plan.steps.map((s) => (
        <div key={s.topic} className="rounded-lg border border-zinc-200 bg-white p-4 dark:border-zinc-700 dark:bg-zinc-900">
          <p data-testid={`remediation-topic-${s.topic}`} className="mb-2 font-semibold">
            {s.topic} <span className="text-amber-600 dark:text-amber-400">{s.pct}%</span>
          </p>
          <div className="mb-2">
            <p className="mb-1 text-xs font-semibold text-zinc-500 uppercase">Redo these lessons/labs</p>
            <ul className="space-y-1 text-sm">
              {s.lessons.map((l) => (
                <li key={l.id}>
                  <Link
                    className="text-sky-600 hover:underline dark:text-sky-400"
                    href={`/units/${l.unitSlug}/${l.slug}` as Route}
                  >
                    {l.title}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
          <div>
            <p className="mb-1 text-xs font-semibold text-zinc-500 uppercase">Drills</p>
            <ul className="space-y-1 text-sm">
              {s.drills.map((d) => (
                <li key={d.id}>
                  <Link className="text-sky-600 hover:underline dark:text-sky-400" href={`/drills?topic=${encodeURIComponent(d.topic)}` as Route}>
                    {d.title}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        </div>
      ))}
      <p className="text-xs text-zinc-500">
        Retake the test until every topic reaches 100. Scores are capped at 100 — no over-scoring.
      </p>
    </section>
  );
}