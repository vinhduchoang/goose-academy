import { describe, expect, it } from "vitest";
import path from "node:path";
import { loadExams } from "@/lib/content-io";
import { parseVerifyVerdict } from "@/lib/lab";
import { canTakeExam, createEmptyProgress, markLabVerified, recordAttempt } from "@/lib/progress";
import type { Attempt } from "@/lib/types";

const CONTENT_ROOT = path.resolve(__dirname, "..", "..", "content");

function pass(id: string, score: number): Attempt {
  return {
    id: `at-${id}-${score}`,
    ts: 1,
    scope: "lesson",
    scopeId: id,
    title: id,
    answers: [0],
    questions: [{ q: "q", options: ["a", "b", "c", "d"], answer: 0, topic: "cargo" }],
    score,
    correct: 1,
    total: 1,
    passed: score >= 80,
    byTopic: { cargo: { correct: 1, total: 1 } },
  };
}

describe("TC-EX-01 exam unlock gating", () => {
  it("every lesson in the unit must be complete", () => {
    let s = createEmptyProgress();
    s = markLabVerified(s, "u0-l01", 1);
    s = recordAttempt(s, pass("u0-l01", 100));
    expect(canTakeExam(s, ["u0-l01"])).toBe(true);
    expect(canTakeExam(s, ["u0-l01", "u0-l02"])).toBe(false);
  });
});

describe("TC-EX-02 mini-lab verdict", () => {
  it("uses passMarkers from the real exam spec", () => {
    const exams = loadExams(CONTENT_ROOT);
    const u0 = exams.find((e) => e.file === "u0.json")!;
    expect(u0.record.miniLab.passMarkers.length).toBeGreaterThanOrEqual(1);
    const passingOutput = u0.record.miniLab.passMarkers.join("\n");
    expect(parseVerifyVerdict(passingOutput, u0.record.miniLab.passMarkers).passed).toBe(true);
    expect(
      parseVerifyVerdict("nothing here", u0.record.miniLab.passMarkers).passed
    ).toBe(false);
  });
});

describe("TC-EX-03 exam records", () => {
  it("u0/u1/u2 have 25 items, u3 has exactly 40", () => {
    const exams = loadExams(CONTENT_ROOT);
    const counts = Object.fromEntries(exams.map((e) => [e.file, e.record.questions.length]));
    expect(counts).toEqual({ "u0.json": 25, "u1.json": 25, "u2.json": 25, "u3.json": 40 });
  });
  it("final exam spans all four units' topics", () => {
    const exams = loadExams(CONTENT_ROOT);
    const final = exams.find((e) => e.file === "u3.json")!.record;
    const topicSet = new Set(final.questions.map((q) => q.topic));
    expect(topicSet.size).toBeGreaterThanOrEqual(20);
  });
});