import type { Attempt, AttemptScope, TestItem } from "@/lib/types";
import { gradeAnswers } from "@/lib/grading";
import { attemptIdFor } from "@/lib/progress";

export function makeAttempt(opts: {
  scope: AttemptScope;
  scopeId: string;
  title: string;
  items: TestItem[];
  answers: (number | null)[];
}): Attempt {
  const result = gradeAnswers(opts.items, opts.answers);
  return {
    id: attemptIdFor(opts.scopeId),
    ts: Date.now(),
    scope: opts.scope,
    scopeId: opts.scopeId,
    title: opts.title,
    answers: opts.answers,
    questions: opts.items.map((i) => ({
      q: i.q,
      options: i.options,
      answer: i.answer,
      topic: i.topic,
    })),
    score: result.score,
    correct: result.correct,
    total: result.total,
    passed: result.passed,
    byTopic: result.byTopic,
  };
}