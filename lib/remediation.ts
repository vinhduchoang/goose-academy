import type { Drill, LessonMeta, TopicLessonsIndex } from "@/lib/types";
import type { GradeResult } from "@/lib/grading";

export const MAX_DRILLS_PER_TOPIC = 3;

export interface WeakTopic {
  topic: string;
  pct: number;
  correct: number;
  total: number;
}

export function weakTopics(result: GradeResult): WeakTopic[] {
  const out: WeakTopic[] = Object.entries(result.byTopic).map(([topic, v]) => ({
    topic,
    correct: v.correct,
    total: v.total,
    pct: v.total === 0 ? 0 : Math.round((v.correct / v.total) * 100),
  }));
  return out.sort((a, b) => a.pct - b.pct || b.total - a.total);
}

export function lessonsCoveringTopic(
  index: TopicLessonsIndex,
  topic: string
): LessonMeta[] {
  return index[topic] ?? [];
}

export function pickDrills(drills: Drill[], topic: string, n: number = 2): Drill[] {
  const match = drills
    .filter((d) => d.topic === topic)
    .slice(0, Math.max(1, Math.min(MAX_DRILLS_PER_TOPIC, n)));
  return match;
}

export interface RemediationPlan {
  weak: WeakTopic[];
  steps: {
    topic: string;
    pct: number;
    lessons: LessonMeta[];
    drills: Drill[];
  }[];
}

export function remediationPlan(
  result: GradeResult,
  index: TopicLessonsIndex,
  drills: Drill[]
): RemediationPlan {
  const weak = weakTopics(result).filter((w) => w.pct < 100);
  return {
    weak,
    steps: weak.map((w) => ({
      topic: w.topic,
      pct: w.pct,
      lessons: lessonsCoveringTopic(index, w.topic),
      drills: pickDrills(drills, w.topic),
    })),
  };
}

export function retakeUntilPerfect(history: number[]): number {
  return history.length;
}

export function bestScoreSoFar(history: number[]): number {
  return history.length === 0 ? 0 : Math.max(...history);
}