import type { Attempt } from "@/lib/types";
import { PASS_THRESHOLD } from "@/lib/grading";

export function ScoreBreakdown({ attempt }: { attempt: Attempt }) {
  const sorted = Object.entries(attempt.byTopic).sort(
    (a, b) => a[1].correct / Math.max(1, a[1].total) - b[1].correct / Math.max(1, b[1].total)
  );
  return (
    <section data-testid="score-breakdown" className="rounded-lg border border-zinc-200 bg-white p-4 dark:border-zinc-700 dark:bg-zinc-900">
      <div className="mb-3 flex items-baseline justify-between">
        <h2 className="text-lg font-bold">Score</h2>
        <p data-testid="score-value" className="text-3xl font-black text-zinc-900 dark:text-zinc-100">
          <span data-testid="score-number">{attempt.score}</span>
          <span className="ml-1 text-sm font-medium text-zinc-500">/ 100</span>
        </p>
      </div>
      <p
        data-testid="score-verdict"
        className={`mb-3 text-sm font-semibold ${attempt.passed ? "text-emerald-600 dark:text-emerald-400" : "text-amber-600 dark:text-amber-400"}`}
      >
        {attempt.passed
          ? "Passed"
          : `Below pass threshold (${PASS_THRESHOLD}) — review and retake to 100.`}
      </p>
      <ul className="space-y-1 text-sm">
        {sorted.map(([topic, v]) => {
          const pct = v.total === 0 ? 0 : Math.round((v.correct / v.total) * 100);
          return (
            <li key={topic} className="flex items-center justify-between gap-2">
              <span className="text-zinc-700 dark:text-zinc-300">{topic}</span>
              <span className={`font-mono text-xs ${pct < PASS_THRESHOLD ? "text-amber-600 dark:text-amber-400" : "text-emerald-600 dark:text-emerald-400"}`}>
                {v.correct}/{v.total} ({pct}%)
              </span>
            </li>
          );
        })}
      </ul>
    </section>
  );
}