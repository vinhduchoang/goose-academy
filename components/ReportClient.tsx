"use client";

import { useParams } from "next/navigation";
import Link from "next/link";
import type { Route } from "next";
import { useProgress } from "@/components/ProgressProvider";
import { ScoreBreakdown } from "@/components/ScoreBreakdown";
import { Remediation } from "@/components/Remediation";
import type { Drill, TopicLessonsIndex } from "@/lib/types";

export function ReportClient({
  topicIndex,
  drills,
}: {
  topicIndex: TopicLessonsIndex;
  drills: Drill[];
}) {
  const params = useParams<{ attempt: string }>();
  const { progress, ready } = useProgress();
  const attempt = progress.attempts[params.attempt];

  if (!ready) return <p className="text-sm text-zinc-500">Loading…</p>;

  if (!attempt) {
    return (
      <div data-testid="report-missing" className="rounded-lg border border-zinc-200 bg-white p-6 text-center dark:border-zinc-700 dark:bg-zinc-900">
        <p className="text-lg font-semibold">Attempt not found</p>
        <p className="mt-1 text-sm text-zinc-500">
          Attempts live in this browser&apos;s LocalStorage. Take the test first, or use the same browser.
        </p>
        <Link className="mt-3 inline-block text-sky-600 hover:underline dark:text-sky-400" href="/" as={"/" as Route} >
          Back to dashboard
        </Link>
      </div>
    );
  }

  const backHref: Route =
    attempt.scope === "exam"
      ? (`/exam/${attempt.scopeId}` as Route)
      : (() => {
          const lessonMeta = Object.values(topicIndex).flat().find((l) => l.id === attempt.scopeId);
          return (`/units/${lessonMeta?.unitSlug ?? "rust-core"}/${lessonMeta?.slug ?? ""}` as Route);
        })();

  return (
    <div className="space-y-6">
      <div>
        <p className="text-xs font-semibold tracking-wide text-zinc-500 uppercase">Assessment report</p>
        <h1 className="mt-1 text-2xl font-black">{attempt.title}</h1>
        <p className="mt-1 text-sm text-zinc-500">
          {new Date(attempt.ts).toLocaleString()} · {attempt.correct}/{attempt.total} correct ·{" "}
          {attempt.scope === "exam" ? "exam" : "lesson test"}
        </p>
      </div>
      <ScoreBreakdown attempt={attempt} />
      <Remediation attempt={attempt} index={topicIndex} drills={drills} />
      <div className="flex gap-3">
        <Link
          data-testid="report-retake"
          className="rounded-md bg-sky-600 px-4 py-2 text-sm font-semibold text-white hover:bg-sky-500"
          href={backHref}
        >
          Retake the test
        </Link>
        <Link
          className="rounded-md border border-zinc-300 px-4 py-2 text-sm font-semibold hover:bg-zinc-100 dark:border-zinc-600 dark:hover:bg-zinc-800"
          href="/"
          as={"/" as Route}
        >
          Dashboard
        </Link>
      </div>
    </div>
  );
}