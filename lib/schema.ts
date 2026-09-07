import { z } from "zod";
import topicsJson from "@/content/topics.json";

export const TOPICS = topicsJson.topics as string[];

export const TOPIC_SCHEMA = z.string().refine((t) => TOPICS.includes(t), {
  message: "topic must be a canonical topic from content/topics.json",
});

export const CITE_SCHEMA = z.object({
  file: z.string().min(1),
  line: z.number().int().positive(),
  note: z.string().optional(),
});

export const FRONTMATTER_SCHEMA = z.object({
  unit: z.number().int().min(0).max(3),
  unitSlug: z.string().min(1),
  order: z.number().int().positive(),
  id: z.string().regex(/^u\d-l\d{2}$/),
  slug: z.string().min(1),
  title: z.string().min(1),
  topics: z.array(TOPIC_SCHEMA).min(1).max(8),
  durationMin: z.number().int().positive(),
  cites: z.array(CITE_SCHEMA),
});

export const TEST_ITEM_SCHEMA = z
  .object({
    q: z.string().min(1),
    options: z.array(z.string().min(1)).length(4),
    answer: z.number().int().min(0).max(3),
    topic: TOPIC_SCHEMA,
    explanation: z.array(z.string().min(1)),
  })
  .superRefine((item, ctx) => {
    if (item.explanation.length !== 3) {
      ctx.addIssue({
        code: "custom",
        message: `explanation must have exactly 3 entries (one per wrong option) for: ${item.q.slice(0, 40)}`,
      });
    }
    if (item.explanation[item.answer] !== undefined && item.explanation.length === 4) {
      ctx.addIssue({
        code: "custom",
        message: "explanation must not cover the correct option",
      });
    }
  });

export const LESSON_TEST_SCHEMA = z
  .array(TEST_ITEM_SCHEMA)
  .min(6)
  .max(8);

export const MINILAB_SCHEMA = z.object({
  title: z.string().min(1),
  instructions: z.string().min(1),
  verifyScript: z.string().min(1),
  passMarkers: z.array(z.string().min(1)).min(1),
});

export const EXAM_SCHEMA = z.object({
  unitSlug: z.string().min(1),
  unitIndex: z.number().int().min(0).max(3),
  title: z.string().min(1),
  questions: z.array(TEST_ITEM_SCHEMA).min(20).max(40),
  miniLab: MINILAB_SCHEMA,
});

export const DRILL_SCHEMA = z.object({
  id: z.string().min(1),
  topic: TOPIC_SCHEMA,
  title: z.string().min(1),
  prompt: z.string().min(1),
  hint: z.string().min(1),
});

export const DRILLS_SCHEMA = z.array(DRILL_SCHEMA).min(16);

export const ATTEMPT_SCHEMA = z.object({
  id: z.string().min(1),
  ts: z.number(),
  scope: z.enum(["lesson", "exam"]),
  scopeId: z.string().min(1),
  title: z.string(),
  answers: z.array(z.number().int().min(0).nullable()),
  questions: z.array(
    z.object({
      q: z.string().min(1),
      options: z.array(z.string().min(1)),
      answer: z.number().int().min(0),
      topic: TOPIC_SCHEMA,
    })
  ),
  score: z.number().min(0).max(100),
  correct: z.number().int().min(0),
  total: z.number().int().min(0),
  passed: z.boolean(),
  byTopic: z.record(
    z.string(),
    z.object({ correct: z.number().int().min(0), total: z.number().int().min(0) })
  ),
});

export const LESSON_PROGRESS_SCHEMA = z.object({
  labVerified: z.boolean(),
  labVerifiedAt: z.number().nullable(),
  bestScore: z.number().min(0).max(100),
  attempts: z.array(z.string()),
});

export const EXAM_PROGRESS_SCHEMA = z.object({
  bestScore: z.number().min(0).max(100),
  attempts: z.array(z.string()),
  miniLabPassed: z.boolean(),
  miniLabOutput: z.string().nullable(),
});

export const PROGRESS_SCHEMA = z.object({
  version: z.literal(1),
  lessons: z.record(z.string(), LESSON_PROGRESS_SCHEMA),
  exams: z.record(z.string(), EXAM_PROGRESS_SCHEMA),
  attempts: z.record(z.string(), ATTEMPT_SCHEMA),
});