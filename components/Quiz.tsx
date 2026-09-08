"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import type { TestItem } from "@/lib/types";
import { makeAttempt } from "@/lib/build-attempt";
import { useProgress } from "@/components/ProgressProvider";
import { recordAttempt } from "@/lib/progress";

export function Quiz({
  items,
  scopeId,
  title,
  scope,
}: {
  items: TestItem[];
  scopeId: string;
  title: string;
  scope: "lesson" | "exam";
}) {
  const router = useRouter();
  const { update } = useProgress();
  const [answers, setAnswers] = useState<(number | null)[]>(() => items.map(() => null));
  const [revealed, setRevealed] = useState(false);
  const [lastAttemptId, setLastAttemptId] = useState<string | null>(null);

  const answeredCount = answers.filter((a) => a !== null).length;
  const allAnswered = answeredCount === items.length;

  function select(i: number, o: number) {
    if (revealed) return;
    setAnswers((prev) => {
      const next = [...prev];
      next[i] = o;
      return next;
    });
  }

  function submit() {
    const attempt = makeAttempt({ scope, scopeId, title, items, answers });
    update((p) => recordAttempt(p, attempt));
    setLastAttemptId(attempt.id);
    setRevealed(true);
  }

  return (
    <div data-testid="quiz" className="space-y-6">
      {items.map((item, i) => (
        <div key={i} className="rounded-lg border border-zinc-200 bg-white p-4 dark:border-zinc-700 dark:bg-zinc-900">
          <p className="mb-3 font-semibold text-zinc-900 dark:text-zinc-100">
            <span className="mr-2 text-xs font-mono text-zinc-400">{i + 1}.</span>
            {item.q}
          </p>
          <div className="space-y-2">
            {item.options.map((opt, oi) => {
              const selected = answers[i] === oi;
              const correct = revealed && item.answer === oi;
              const wrongPick = revealed && selected && item.answer !== oi;
              const cls = selected
                ? "border-sky-500 bg-sky-50 dark:bg-sky-950/40 ring-1 ring-sky-500"
                : "border-zinc-200 hover:border-zinc-400 dark:border-zinc-700";
              const extra = correct
                ? " border-emerald-500 bg-emerald-50 dark:bg-emerald-950/40 ring-1 ring-emerald-500"
                : wrongPick
                  ? " border-red-400 bg-red-50 dark:bg-red-950/40 ring-1 ring-red-400"
                  : "";
              return (
                <button
                  key={oi}
                  type="button"
                  data-testid={`quiz-option-${i}-${oi}`}
                  onClick={() => select(i, oi)}
                  className={`block w-full rounded-lg border px-3 py-2 text-left text-sm transition ${cls} ${revealed ? extra : ""} ${revealed ? "cursor-default" : "cursor-pointer"}`}
                >
                  {opt}
                </button>
              );
            })}
          </div>
          {revealed && (
            <div className="mt-3 space-y-1 rounded-md bg-zinc-50 p-3 text-sm dark:bg-zinc-800">
              {item.answer !== answers[i] && (
                <p className="font-medium text-red-600 dark:text-red-400">
                  {answers[i] === null ? "Unanswered." : "You missed this one."}
                </p>
              )}
              <p className="font-medium text-emerald-700 dark:text-emerald-400">
                Correct: option {item.answer + 1}
              </p>
              {(() => {
                const wrong = item.options.map((_, oi) => oi).filter((oi) => oi !== item.answer);
                const letters = ["a", "b", "c", "d"];
                return (
                  <ul className="space-y-1 text-zinc-600 dark:text-zinc-300">
                    {wrong.map((oi, exIdx) => (
                      <li key={oi}>
                        <strong className="text-zinc-700 dark:text-zinc-200">Why not {letters[oi]}?</strong>{" "}
                        {item.explanation[exIdx] ?? ""}
                      </li>
                    ))}
                  </ul>
                );
              })()}
            </div>
          )}
        </div>
      ))}
      <div className="sticky bottom-4 flex items-center justify-between rounded-lg border border-zinc-200 bg-white/95 p-3 shadow-lg backdrop-blur dark:border-zinc-700 dark:bg-zinc-900/95">
        <p className="text-sm text-zinc-600 dark:text-zinc-300">
          {answeredCount}/{items.length} answered
          {revealed && <span className="ml-2 text-zinc-400">— review, then retake to 100</span>}
        </p>
        {revealed ? (
          <div className="flex gap-2">
            {lastAttemptId && (
              <button
                type="button"
                data-testid="quiz-view-report"
                onClick={() => router.push(`/report/${lastAttemptId}`)}
                className="rounded-md bg-sky-600 px-4 py-2 text-sm font-semibold text-white hover:bg-sky-500"
              >
                View report
              </button>
            )}
            <button
              type="button"
              data-testid="quiz-retake"
              onClick={() => {
                setAnswers(items.map(() => null));
                setRevealed(false);
                setLastAttemptId(null);
              }}
              className="rounded-md border border-zinc-300 px-4 py-2 text-sm font-semibold hover:bg-zinc-100 dark:border-zinc-600 dark:hover:bg-zinc-800"
            >
              Retake
            </button>
          </div>
        ) : (
          <button
            type="button"
            data-testid="quiz-submit"
            disabled={!allAnswered}
            onClick={submit}
            className="rounded-md bg-sky-600 px-4 py-2 text-sm font-semibold text-white hover:bg-sky-500 disabled:cursor-not-allowed disabled:opacity-40"
          >
            Submit test
          </button>
        )}
      </div>
    </div>
  );
}