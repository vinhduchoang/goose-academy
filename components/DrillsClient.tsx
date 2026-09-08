"use client";

import Link from "next/link";
import type { Route } from "next";
import { useState } from "react";
import type { Drill } from "@/lib/types";

export function DrillsClient({
  drills,
  initialTopic,
}: {
  drills: Drill[];
  initialTopic: string | null;
}) {
  const [topic, setTopic] = useState<string | null>(initialTopic);
  const topics = Array.from(new Set(drills.map((d) => d.topic))).sort();
  const filtered = topic ? drills.filter((d) => d.topic === topic) : drills;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-black tracking-tight">Drill bank</h1>
        <p className="mt-2 max-w-xl text-sm text-zinc-600 dark:text-zinc-300">
          Timed-ish micro-exercises per topic. The remediation engine links here whenever a
          topic drops below 100. Nudge first — no full answers.
        </p>
      </div>
      <div className="flex flex-wrap gap-2" data-testid="drill-filter">
        <button
          type="button"
          onClick={() => setTopic(null)}
          className={`rounded-full px-3 py-1 text-xs font-semibold ${
            topic === null
              ? "bg-zinc-800 text-white dark:bg-zinc-200 dark:text-zinc-900"
              : "bg-zinc-200 text-zinc-700 hover:bg-zinc-300 dark:bg-zinc-800 dark:text-zinc-300"
          }`}
        >
          all ({drills.length})
        </button>
        {topics.map((t) => (
          <button
            key={t}
            type="button"
            data-testid={`drill-filter-${t}`}
            onClick={() => setTopic(t)}
            className={`rounded-full px-3 py-1 text-xs font-semibold ${
              topic === t
                ? "bg-sky-600 text-white"
                : "bg-zinc-200 text-zinc-700 hover:bg-zinc-300 dark:bg-zinc-800 dark:text-zinc-300"
            }`}
          >
            {t}
          </button>
        ))}
      </div>
      <ul className="space-y-3">
        {filtered.map((d) => (
          <li key={d.id} className="rounded-lg border border-zinc-200 bg-white p-4 dark:border-zinc-700 dark:bg-zinc-900">
            <div className="flex items-center justify-between gap-2">
              <h2 className="font-bold">{d.title}</h2>
              <Link
                className="shrink-0 text-xs text-zinc-500 hover:text-zinc-800 dark:hover:text-zinc-200"
                href={`/drills?topic=${encodeURIComponent(d.topic)}` as Route}
              >
                {d.topic}
              </Link>
            </div>
            <p className="mt-2 text-sm text-zinc-700 dark:text-zinc-300">{d.prompt}</p>
            <details className="mt-3">
              <summary className="cursor-pointer text-xs font-semibold text-sky-600 dark:text-sky-400">
                Hint
              </summary>
              <p className="mt-1 text-sm text-zinc-600 dark:text-zinc-400">{d.hint}</p>
            </details>
          </li>
        ))}
      </ul>
    </div>
  );
}