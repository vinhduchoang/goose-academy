import { describe, expect, it } from "vitest";
import {
  PASS_THRESHOLD,
  clampScore,
  computeScore,
  gradeAnswers,
  isPassScore,
  topicBreakdown,
} from "@/lib/grading";
import type { TestItem } from "@/lib/types";

function item(q: string, topic: string, answer = 0): TestItem {
  return { q, options: ["a", "b", "c", "d"], answer, topic, explanation: ["x", "y", "z"] };
}

describe("TC-GR-01 score math", () => {
  it("computes rounded percentages", () => {
    expect(computeScore(1, 3)).toBe(33);
    expect(computeScore(2, 3)).toBe(67);
    expect(computeScore(5, 8)).toBe(63);
    expect(computeScore(0, 0)).toBe(0);
  });
});

describe("TC-GR-02 cap at 100", () => {
  it("never exceeds 100", () => {
    expect(clampScore(150)).toBe(100);
    expect(clampScore(-5)).toBe(0);
    expect(computeScore(10, 8)).toBe(100);
  });
  it("gradeAnswers respects the cap", () => {
    const items = [item("1", "cargo"), item("2", "cargo")];
    expect(gradeAnswers(items, [0, 0]).score).toBe(100);
  });
});

describe("TC-GR-03 topic aggregation", () => {
  it("aggregates per topic including unanswered", () => {
    const items = [
      item("1", "cargo", 0),
      item("2", "cargo", 1),
      item("3", "serde", 2),
    ];
    const b = topicBreakdown(items, [0, null, 3]);
    expect(b).toEqual({
      cargo: { correct: 1, total: 2 },
      serde: { correct: 0, total: 1 },
    });
  });
});

describe("TC-GR-04 pass threshold", () => {
  it("is 80", () => {
    expect(PASS_THRESHOLD).toBe(80);
    expect(isPassScore(79)).toBe(false);
    expect(isPassScore(80)).toBe(true);
    const items = [item("1", "cargo"), item("2", "cargo"), item("3", "cargo"), item("4", "cargo"), item("5", "cargo")];
    expect(gradeAnswers(items, [0, 0, 0, 0, 2]).passed).toBe(true);
    expect(gradeAnswers(items, [0, 0, 0, 1, 2]).passed).toBe(false);
  });
});

describe("TC-GR-05 unanswered items", () => {
  it("null answers are wrong but still count in total", () => {
    const items = [item("1", "cargo"), item("2", "cargo"), item("3", "cargo")];
    const r = gradeAnswers(items, [0, null, null]);
    expect(r.correct).toBe(1);
    expect(r.total).toBe(3);
    expect(r.score).toBe(33);
    expect(r.passed).toBe(false);
  });
});