import { describe, expect, it } from "vitest";
import {
  STORAGE_KEY,
  canTakeExam,
  createEmptyProgress,
  lessonAccessor,
  lessonIsComplete,
  loadProgress,
  markLabVerified,
  markMiniLab,
  recordAttempt,
  sanitizeStored,
  saveProgress,
  unitStats,
} from "@/lib/progress";
import type { Attempt } from "@/lib/types";

function attempt(scopeId: string, score: number, scope: "lesson" | "exam" = "lesson"): Attempt {
  return {
    id: `at-${scopeId}-${score}`,
    ts: Date.now(),
    scope,
    scopeId,
    title: scopeId,
    answers: [0],
    questions: [{ q: "q", options: ["a", "b", "c", "d"], answer: 0, topic: "cargo" }],
    score,
    correct: 1,
    total: 1,
    passed: score >= 80,
    byTopic: { cargo: { correct: 1, total: 1 } },
  };
}

interface MemStorage {
  getItem(k: string): string | null;
  setItem(k: string, v: string): void;
}

class Mem implements MemStorage {
  map = new Map<string, string>();
  getItem(k: string) {
    return this.map.get(k) ?? null;
  }
  setItem(k: string, v: string) {
    this.map.set(k, v);
  }
}

describe("TC-PR-01 lesson complete rule", () => {
  it("requires lab AND >=80 best score", () => {
    let s = createEmptyProgress();
    expect(lessonIsComplete(s, "u0-l01")).toBe(false);
    s = recordAttempt(s, attempt("u0-l01", 79));
    expect(lessonIsComplete(s, "u0-l01")).toBe(false);
    s = recordAttempt(s, attempt("u0-l01", 90));
    expect(lessonIsComplete(s, "u0-l01")).toBe(false);
    s = markLabVerified(s, "u0-l01", 123);
    expect(lessonIsComplete(s, "u0-l01")).toBe(true);
  });
  it("best score never regresses", () => {
    let s = createEmptyProgress();
    s = recordAttempt(s, attempt("u0-l01", 100));
    s = recordAttempt(s, attempt("u0-l01", 10));
    expect(lessonAccessor(s, "u0-l01").bestScore).toBe(100);
  });
});

describe("TC-PR-02 attempt history", () => {
  it("keeps every attempt and links to lesson", () => {
    let s = createEmptyProgress();
    s = recordAttempt(s, attempt("u0-l01", 50));
    s = recordAttempt(s, attempt("u0-l01", 70));
    expect(lessonAccessor(s, "u0-l01").attempts).toHaveLength(2);
    expect(Object.keys(s.attempts)).toHaveLength(2);
    expect(s.attempts["at-u0-l01-70"]).toBeDefined();
  });
  it("records exams separately", () => {
    let s = createEmptyProgress();
    s = recordAttempt(s, attempt("rust-core", 90, "exam"));
    expect(s.exams["rust-core"].bestScore).toBe(90);
  });
});

describe("TC-PR-03 localStorage round-trip", () => {
  it("persists and restores", () => {
    const mem = new Mem();
    let s = createEmptyProgress();
    s = markLabVerified(s, "u0-l01", 42);
    saveProgress(mem, s);
    expect(mem.getItem(STORAGE_KEY)).toBeTruthy();
    const restored = loadProgress(mem);
    expect(restored.lessons["u0-l01"].labVerified).toBe(true);
  });
  it("drops corrupt data safely", () => {
    const mem = new Mem();
    mem.setItem(STORAGE_KEY, "{not json");
    expect(loadProgress(mem)).toEqual(createEmptyProgress());
    mem.setItem(STORAGE_KEY, JSON.stringify({ version: 99 }));
    expect(loadProgress(mem)).toEqual(createEmptyProgress());
    expect(sanitizeStored(null)).toEqual(createEmptyProgress());
  });
  it("drops data with capped-by-schema scores", () => {
    const mem = new Mem();
    mem.setItem(
      STORAGE_KEY,
      JSON.stringify({
        version: 1,
        lessons: { "u0-l01": { labVerified: true, labVerifiedAt: 1, bestScore: 999, attempts: [] } },
        exams: {},
        attempts: {},
      })
    );
    expect(loadProgress(mem)).toEqual(createEmptyProgress());
  });
});

describe("TC-PR-04 exam gate", () => {
  it("unlocks only when every lesson complete", () => {
    let s = createEmptyProgress();
    s = markLabVerified(s, "u0-l01", 1);
    s = recordAttempt(s, attempt("u0-l01", 100));
    expect(canTakeExam(s, ["u0-l01"])).toBe(true);
    expect(canTakeExam(s, ["u0-l01", "u0-l02"])).toBe(false);
    const stats = unitStats(s, ["u0-l01", "u0-l02"], "rust-core");
    expect(stats.complete).toBe(1);
    expect(stats.examEligible).toBe(false);
  });
  it("tracks exam attempts in stats", () => {
    let s = createEmptyProgress();
    s = recordAttempt(s, attempt("rust-core", 95, "exam"));
    expect(unitStats(s, [], "rust-core").examBest).toBe(95);
    s = markMiniLab(s, "rust-core", "VERIFY PASSED 5/5", true);
    expect(s.exams["rust-core"].miniLabPassed).toBe(true);
  });
});