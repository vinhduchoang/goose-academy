import { describe, expect, it } from "vitest";
import {
  MAX_DRILLS_PER_TOPIC,
  lessonsCoveringTopic,
  pickDrills,
  remediationPlan,
  weakTopics,
} from "@/lib/remediation";
import type { GradeResult } from "@/lib/grading";
import type { Drill, LessonMeta } from "@/lib/types";

const lesson = (id: string, topic: string): LessonMeta => ({
  id,
  slug: id,
  unitIndex: 0,
  unitSlug: "rust-core",
  order: 1,
  title: id,
  topics: [topic],
  cites: [],
  durationMin: 20,
});

const index = {
  cargo: [lesson("u0-l01", "cargo"), lesson("u0-l13", "cargo")],
  ownership: [lesson("u0-l07", "ownership")],
};

const drills: Drill[] = [
  { id: "d1", topic: "ownership", title: "t1", prompt: "p", hint: "h" },
  { id: "d2", topic: "ownership", title: "t2", prompt: "p", hint: "h" },
  { id: "d3", topic: "ownership", title: "t3", prompt: "p", hint: "h" },
  { id: "d4", topic: "ownership", title: "t4", prompt: "p", hint: "h" },
  { id: "d5", topic: "cargo", title: "t5", prompt: "p", hint: "h" },
];

const result: GradeResult = {
  correct: 5,
  total: 10,
  score: 50,
  passed: false,
  byTopic: {
    cargo: { correct: 3, total: 4 },
    ownership: { correct: 0, total: 3 },
    serde: { correct: 2, total: 3 },
  },
};

describe("TC-RE-01 weak topic ranking", () => {
  it("sorts weakest first", () => {
    const w = weakTopics(result);
    expect(w.map((x) => x.topic)).toEqual(["ownership", "serde", "cargo"]);
    expect(w[0].pct).toBe(0);
  });
});

describe("TC-RE-02 topic to lesson mapping", () => {
  it("returns lessons covering the topic", () => {
    expect(lessonsCoveringTopic(index, "cargo")).toHaveLength(2);
    expect(lessonsCoveringTopic(index, "serde")).toHaveLength(0);
  });
});

describe("TC-RE-03 drill selection", () => {
  it("caps drills per topic", () => {
    expect(MAX_DRILLS_PER_TOPIC).toBe(3);
    const picked = pickDrills(drills, "ownership", 2);
    expect(picked).toHaveLength(2);
    expect(pickDrills(drills, "ownership", 10)).toHaveLength(3);
    expect(pickDrills(drills, "serde")).toHaveLength(0);
  });
});

describe("TC-RE-04 remediation plan retake loop", () => {
  it("only includes topics below 100 with lessons and drills", () => {
    const plan = remediationPlan(result, index, drills);
    expect(plan.weak.map((w) => w.topic)).toEqual(["ownership", "serde", "cargo"]);
    const ownership = plan.steps.find((s) => s.topic === "ownership")!;
    expect(ownership.lessons).toHaveLength(1);
    expect(ownership.drills).toHaveLength(2);
  });
  it("empty when everything is 100", () => {
    const perfect: GradeResult = {
      ...result,
      byTopic: { cargo: { correct: 4, total: 4 } },
    };
    expect(remediationPlan(perfect, index, drills).weak).toHaveLength(0);
  });
});