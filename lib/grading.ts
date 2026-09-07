import type { TestItem } from "@/lib/types";

export const PASS_THRESHOLD = 80;
export const SCORE_CAP = 100;

export function clampScore(raw: number): number {
  return Math.max(0, Math.min(SCORE_CAP, Math.round(raw)));
}

export function computeScore(correct: number, total: number): number {
  if (total <= 0) return 0;
  return clampScore((correct / total) * 100);
}

export interface TopicBreakdown {
  [topic: string]: { correct: number; total: number };
}

export interface GradeResult {
  correct: number;
  total: number;
  score: number;
  passed: boolean;
  byTopic: TopicBreakdown;
}

export function topicBreakdown(
  items: Pick<TestItem, "topic">[],
  answers: (number | null)[]
): TopicBreakdown {
  const byTopic: TopicBreakdown = {};
  items.forEach((item, i) => {
    const t = byTopic[item.topic] ?? { correct: 0, total: 0 };
    byTopic[item.topic] = t;
    t.total += 1;
    if (answers[i] === null || answers[i] === undefined) return;
    if (answers[i] === (items[i] as TestItem).answer) t.correct += 1;
  });
  return byTopic;
}

export function gradeAnswers(
  items: TestItem[],
  answers: (number | null)[]
): GradeResult {
  const total = items.length;
  let correct = 0;
  const byTopic = topicBreakdown(items, answers);
  items.forEach((item, i) => {
    if (answers[i] === null || answers[i] === undefined) return;
    if (Number(answers[i]) === item.answer) correct += 1;
  });
  return {
    correct,
    total,
    score: computeScore(correct, total),
    passed: computeScore(correct, total) >= PASS_THRESHOLD,
    byTopic,
  };
}

export function isPassScore(score: number): boolean {
  return score >= PASS_THRESHOLD;
}