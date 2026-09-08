import { PASS_THRESHOLD, clampScore } from "@/lib/grading";
import { PROGRESS_SCHEMA } from "@/lib/schema";
import type { Attempt, ProgressState } from "@/lib/types";

export const STORAGE_KEY = "goose-academy-progress-v1";

export function createEmptyProgress(): ProgressState {
  return { version: 1, lessons: {}, exams: {}, attempts: {} };
}

export function sanitizeStored(value: string | null): ProgressState {
  if (!value) return createEmptyProgress();
  let parsed: unknown = null;
  try {
    parsed = JSON.parse(value);
  } catch {
    return createEmptyProgress();
  }
  const result = PROGRESS_SCHEMA.safeParse(parsed);
  if (!result.success) return createEmptyProgress();
  return result.data;
}

export function serializeProgress(state: ProgressState): string {
  return JSON.stringify(state);
}

export function lessonAccessor(state: ProgressState, id: string) {
  return (
    state.lessons[id] ?? {
      labVerified: false,
      labVerifiedAt: null,
      bestScore: 0,
      attempts: [],
    }
  );
}

export function lessonIsComplete(state: ProgressState, id: string): boolean {
  const l = lessonAccessor(state, id);
  return l.labVerified && l.bestScore >= PASS_THRESHOLD;
}

export function lessonBestScore(state: ProgressState, id: string): number {
  return lessonAccessor(state, id).bestScore;
}

export function recordAttempt(state: ProgressState, attempt: Attempt): ProgressState {
  const next: ProgressState = {
    ...state,
    attempts: { ...state.attempts, [attempt.id]: attempt },
  };
  if (attempt.scope === "lesson") {
    const prev = lessonAccessor(next, attempt.scopeId);
    next.lessons = {
      ...next.lessons,
      [attempt.scopeId]: {
        ...prev,
        bestScore: Math.max(prev.bestScore, attempt.score),
        attempts: [...prev.attempts, attempt.id],
      },
    };
  } else {
    const prev = next.exams[attempt.scopeId] ?? {
      bestScore: 0,
      attempts: [],
      miniLabPassed: false,
      miniLabOutput: null,
    };
    next.exams = {
      ...next.exams,
      [attempt.scopeId]: {
        ...prev,
        bestScore: Math.max(prev.bestScore, attempt.score),
        attempts: [...prev.attempts, attempt.id],
      },
    };
  }
  return next;
}

export function markLabVerified(state: ProgressState, id: string, at: number): ProgressState {
  const prev = lessonAccessor(state, id);
  return {
    ...state,
    lessons: {
      ...state.lessons,
      [id]: { ...prev, labVerified: true, labVerifiedAt: prev.labVerifiedAt ?? at },
    },
  };
}

export function markMiniLab(state: ProgressState, unitSlug: string, output: string, passed: boolean): ProgressState {
  const prev = state.exams[unitSlug] ?? {
    bestScore: 0,
    attempts: [],
    miniLabPassed: false,
    miniLabOutput: null,
  };
  return {
    ...state,
    exams: {
      ...state.exams,
      [unitSlug]: { ...prev, miniLabPassed: passed, miniLabOutput: output },
    },
  };
}

export function canTakeExam(state: ProgressState, lessonIds: string[]): boolean {
  return lessonIds.every((id) => lessonIsComplete(state, id));
}

export function unitStats(
  state: ProgressState,
  lessonIds: string[],
  unitSlug: string
) {
  const complete = lessonIds.filter((id) => lessonIsComplete(state, id)).length;
  return {
    total: lessonIds.length,
    complete,
    pct: lessonIds.length === 0 ? 0 : clampScore((complete / lessonIds.length) * 100),
    examEligible: canTakeExam(state, lessonIds),
    examBest: state.exams[unitSlug]?.bestScore ?? 0,
  };
}

export interface FakeStorage {
  getItem(key: string): string | null;
  setItem(key: string, value: string): void;
}

export function loadProgress(storage: FakeStorage): ProgressState {
  return sanitizeStored(storage.getItem(STORAGE_KEY));
}

export function saveProgress(storage: FakeStorage, state: ProgressState): void {
  storage.setItem(STORAGE_KEY, serializeProgress(state));
}

export function attemptIdFor(scopeId: string): string {
  const iso = new Date().toISOString().replace(/[:.]/g, "-");
  return `at-${scopeId}-${iso}`;
}