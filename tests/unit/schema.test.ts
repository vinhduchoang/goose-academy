import { describe, expect, it } from "vitest";
import path from "node:path";
import {
  FRONTMATTER_SCHEMA,
  LESSON_TEST_SCHEMA,
  TEST_ITEM_SCHEMA,
  TOPICS,
  EXAM_SCHEMA,
  DRILLS_SCHEMA,
} from "@/lib/schema";
import { loadAllLessons, loadDrills, loadExams, validateExam } from "@/lib/content-io";

const CONTENT_ROOT = path.resolve(__dirname, "..", "..", "content");

describe("TC-CS-01 example test payloads valid", () => {
  it("exemplar lesson parses", () => {
    const lessons = loadAllLessons(CONTENT_ROOT);
    const l01 = lessons.find((l) => l.frontmatter?.id === "u0-l01");
    expect(l01?.issues).toHaveLength(0);
    expect(l01?.frontmatter?.topics).toContain("cargo");
    expect(l01?.test).toBeTruthy();
  });
  it("every lesson in content/ is schema-valid", () => {
    const lessons = loadAllLessons(CONTENT_ROOT);
    expect(lessons).toHaveLength(46);
    const bad = lessons.map((l) => ({ id: l.frontmatter?.id, issues: l.issues }));
    expect(bad.filter((b) => b.issues.length > 0)).toEqual([]);
  });
  it("every exam and the drill bank are schema-valid", () => {
    const exams = loadExams(CONTENT_ROOT);
    expect(exams).toHaveLength(4);
    for (const { file, record } of exams) {
      expect(validateExam(file, record, file === "u3.json" ? 40 : 25)).toEqual([]);
    }
    const { drills, issues } = loadDrills(CONTENT_ROOT);
    expect(issues).toEqual([]);
    expect(drills.length).toBeGreaterThanOrEqual(16);
  });
});

describe("TC-CS-02 invalid payloads rejected", () => {
  it("rejects bad item shapes", () => {
    expect(
      LESSON_TEST_SCHEMA.safeParse([{ q: "", options: ["a"], answer: 0, topic: "cargo", explanation: [] }]).success
    ).toBe(false);
    const wrongExplanation = { q: "x", options: ["a", "b", "c", "d"], answer: 0, topic: "cargo", explanation: ["1", "2"] };
    expect(TEST_ITEM_SCHEMA.safeParse(wrongExplanation).success).toBe(false);
    const answerOutOfRange = { q: "x", options: ["a", "b", "c", "d"], answer: 4, topic: "cargo", explanation: ["1", "2", "3"] };
    expect(TEST_ITEM_SCHEMA.safeParse(answerOutOfRange).success).toBe(false);
  });
  it("rejects unknown topics", () => {
    const bad = { q: "x", options: ["a", "b", "c", "d"], answer: 0, topic: "not-a-topic", explanation: ["1", "2", "3"] };
    expect(TEST_ITEM_SCHEMA.safeParse(bad).success).toBe(false);
  });
  it("rejects wrong question counts", () => {
    expect(EXAM_SCHEMA.safeParse({ unitSlug: "x", unitIndex: 0, title: "t", questions: [], miniLab: { title: "m", instructions: "i", verifyScript: "v", passMarkers: ["p"] } }).success).toBe(false);
    expect(DRILLS_SCHEMA.safeParse([]).success).toBe(false);
  });
});

describe("TC-CS-03 canonical topics", () => {
  it("all lesson/exam/drill topics are canonical", () => {
    for (const l of loadAllLessons(CONTENT_ROOT)) {
      for (const t of l.frontmatter?.topics ?? []) expect(TOPICS).toContain(t);
      for (const item of l.test ?? []) expect(TOPICS).toContain(item.topic);
    }
    for (const { record } of loadExams(CONTENT_ROOT)) {
      for (const q of record.questions) expect(TOPICS).toContain(q.topic);
    }
    for (const d of loadDrills(CONTENT_ROOT).drills) expect(TOPICS).toContain(d.topic);
  });
});

describe("TC-CS-04 frontmatter required fields", () => {
  it("has all keys on every lesson", () => {
    for (const l of loadAllLessons(CONTENT_ROOT)) {
      const fm = l.frontmatter;
      expect(fm).not.toBeNull();
      expect(fm!.unit).toBeGreaterThanOrEqual(0);
      expect(fm!.order).toBeGreaterThan(0);
      expect(fm!.id).toMatch(/^u\d-l\d{2}$/);
      expect(fm!.slug.length).toBeGreaterThan(0);
      expect(fm!.cites.length).toBeGreaterThanOrEqual(1);
    }
  });
});

describe("TC-CS-05 id/slug uniqueness", () => {
  it("no duplicates", () => {
    const lessons = loadAllLessons(CONTENT_ROOT);
    const ids = new Set(lessons.map((l) => l.frontmatter!.id));
    expect(ids.size).toBe(46);
    const routes = new Set(lessons.map((l) => `${l.frontmatter!.unitSlug}/${l.frontmatter!.slug}`));
    expect(routes.size).toBe(46);
    const frontmatterParse = FRONTMATTER_SCHEMA.safeParse(lessons[0].frontmatter);
    expect(frontmatterParse.success).toBe(true);
  });
});