"use client";

import { useState } from "react";
import Link from "next/link";
import type { Route } from "next";
import type { LessonMeta, TestItem } from "@/lib/types";
import { Quiz } from "@/components/Quiz";
import { LabRunner } from "@/components/LabRunner";
import { useProgress } from "@/components/ProgressProvider";
import { lessonAccessor } from "@/lib/progress";

type Tab = "theory" | "lab" | "test";

export function LessonPageClient({
  lesson,
  theory,
  lab,
  test,
  verifyScript,
  prev,
  next,
}: {
  lesson: LessonMeta;
  theory: React.ReactNode;
  lab: React.ReactNode;
  test: TestItem[];
  verifyScript: string;
  prev: { title: string; slug: string } | null;
  next: { title: string; slug: string } | null;
}) {
  const [tab, setTab] = useState<Tab>("theory");
  const { progress } = useProgress();
  const lp = lessonAccessor(progress, lesson.id);
  const complete = lp.labVerified && lp.bestScore >= 80;

  const tabs: { id: Tab; label: string; badge?: string }[] = [
    { id: "theory", label: "Theory" },
    { id: "lab", label: "Lab", badge: lp.labVerified ? "✓" : undefined },
    { id: "test", label: "Test", badge: lp.bestScore >= 80 ? `${lp.bestScore}` : undefined },
  ];

  return (
    <div className="space-y-6">
      <div>
        <p className="text-xs font-semibold tracking-wide text-zinc-500 uppercase">
          Unit {lesson.unitIndex} · Lesson {lesson.order}
          {complete && (
            <span data-testid="lesson-complete-chip" className="ml-2 rounded-full bg-emerald-100 px-2 py-0.5 text-emerald-700 dark:bg-emerald-900 dark:text-emerald-300">
              complete
            </span>
          )}
        </p>
        <h1 className="mt-1 text-3xl font-black tracking-tight">{lesson.title}</h1>
        <div className="mt-2 flex flex-wrap items-center gap-2 text-xs">
          <span className="rounded-full bg-zinc-200 px-2 py-0.5 text-zinc-700 dark:bg-zinc-800 dark:text-zinc-300">
            {lesson.durationMin} min theory
          </span>
          {lesson.topics.map((t) => (
            <span key={t} className="rounded-full bg-sky-100 px-2 py-0.5 text-sky-700 dark:bg-sky-900 dark:text-sky-300">
              {t}
            </span>
          ))}
        </div>
      </div>

      <div className="flex gap-1 border-b border-zinc-200 dark:border-zinc-700">
        {tabs.map((t) => (
          <button
            key={t.id}
            type="button"
            data-testid={`tab-${t.id}`}
            onClick={() => setTab(t.id)}
            className={`-mb-px rounded-t-lg border-b-2 px-4 py-2 text-sm font-semibold transition ${
              tab === t.id
                ? "border-sky-500 text-sky-600 dark:text-sky-400"
                : "border-transparent text-zinc-500 hover:text-zinc-800 dark:hover:text-zinc-200"
            }`}
          >
            {t.label}
            {t.badge && <span className="ml-1.5 text-xs">{t.badge}</span>}
          </button>
        ))}
      </div>

      {tab === "theory" && (
        <article className="prose prose-zinc dark:prose-invert max-w-none">{theory}</article>
      )}

      {tab === "lab" && (
        <div className="space-y-6">
          <article className="prose prose-zinc dark:prose-invert max-w-none">{lab}</article>
          <LabRunner lessonId={lesson.id} verifyScript={verifyScript} />
        </div>
      )}

      {tab === "test" && (
        <Quiz items={test} scopeId={lesson.id} title={lesson.title} scope="lesson" />
      )}

      <div className="flex items-center justify-between border-t border-zinc-200 pt-4 text-sm dark:border-zinc-700">
        {prev ? (
          <Link className="text-zinc-500 hover:text-zinc-800 dark:hover:text-zinc-200" href={`/units/${lesson.unitSlug}/${prev.slug}` as Route}>
            ← {prev.title}
          </Link>
        ) : (
          <Link className="text-zinc-500 hover:text-zinc-800 dark:hover:text-zinc-200" href={`/units/${lesson.unitSlug}` as Route}>
            ← Unit overview
          </Link>
        )}
        {next && (
          <Link className="font-semibold text-sky-600 hover:text-sky-500 dark:text-sky-400" href={`/units/${lesson.unitSlug}/${next.slug}` as Route}>
            {next.title} →
          </Link>
        )}
      </div>
    </div>
  );
}