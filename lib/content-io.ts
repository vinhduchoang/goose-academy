import fs from "node:fs";
import path from "node:path";
import { z } from "zod";
import { parseFrontmatterRaw } from "@/lib/fmparse";
import {
  DRILLS_SCHEMA,
  EXAM_SCHEMA,
  FRONTMATTER_SCHEMA,
  LESSON_TEST_SCHEMA,
  TOPICS,
} from "@/lib/schema";
import type { Cite, Drill, ExamRecord, LessonFrontmatter, TestItem } from "@/lib/types";

export interface ContentIssue {
  path: string;
  message: string;
}

export function lessonDirs(contentRoot: string): string[] {
  const unitsDir = path.join(contentRoot, "units");
  if (!fs.existsSync(unitsDir)) return [];
  const out: string[] = [];
  for (const unit of fs.readdirSync(unitsDir)) {
    const unitDir = path.join(unitsDir, unit);
    if (!fs.statSync(unitDir).isDirectory()) continue;
    for (const lesson of fs.readdirSync(unitDir)) {
      const lessonDir = path.join(unitDir, lesson);
      if (fs.statSync(lessonDir).isDirectory()) out.push(lessonDir);
    }
  }
  return out.sort();
}

export function parseLessonFolder(lessonDir: string, contentRoot: string) {
  const dir = path.isAbsolute(lessonDir) ? lessonDir : path.join(contentRoot, lessonDir);
  const mdxPath = path.join(dir, "lesson.mdx");
  const labPath = path.join(dir, "lab.md");
  const verifyPath = path.join(dir, "verify.ps1");
  const testPath = path.join(dir, "test.json");
  const issues: ContentIssue[] = [];
  for (const f of [mdxPath, labPath, verifyPath, testPath]) {
    if (!fs.existsSync(f)) issues.push({ path: f.replace(contentRoot + path.sep, ""), message: "missing required file" });
  }
  if (issues.length > 0) return { issues };

  const raw = fs.readFileSync(mdxPath, "utf8");
  const parsedFm = parseFrontmatterRaw(raw);
  if (!parsedFm) {
    issues.push({ path: mdxPath.replace(contentRoot + path.sep, ""), message: "missing YAML frontmatter block" });
    return { issues };
  }
  const { data, content } = parsedFm;
  if (content.trim().length < 100) {
    issues.push({ path: mdxPath.replace(contentRoot + path.sep, ""), message: "theory body suspiciously short" });
  }
  const fm = FRONTMATTER_SCHEMA.safeParse(data);
  if (!fm.success) {
    for (const err of fm.error.issues) {
      issues.push({
        path: mdxPath.replace(contentRoot + path.sep, ""),
        message: `frontmatter: ${err.path.join(".") || "(root)"}: ${err.message}`,
      });
    }
    return { issues, frontmatter: null, test: null, verify: "" };
  }
  const f = fm.data;
  const testRaw = fs.readFileSync(testPath, "utf8");
  let test: TestItem[] | null = null;
  try {
    const parsed = JSON.parse(testRaw);
    const t = LESSON_TEST_SCHEMA.safeParse(parsed);
    if (!t.success) {
      for (const err of t.error.issues) {
        issues.push({ path: testPath.replace(contentRoot + path.sep, ""), message: err.message });
      }
    } else {
      test = t.data;
      test.forEach((item, i) => {
        if (!TOPICS.includes(item.topic)) {
          issues.push({ path: testPath.replace(contentRoot + path.sep, ""), message: `item ${i}: unknown topic "${item.topic}"` });
        }
      });
    }
  } catch (e) {
    issues.push({ path: testPath.replace(contentRoot + path.sep, ""), message: `invalid JSON: ${(e as Error).message}` });
  }
  const verify = fs.readFileSync(verifyPath, "utf8");
  if (!verify.includes("VERIFY PASSED") || (!verify.includes("exit 0") && !verify.includes("EXIT 0"))) {
    issues.push({ path: verifyPath.replace(contentRoot + path.sep, ""), message: "verify.ps1 must emit VERIFY PASSED and exit 0" });
  }
  return {
    issues,
    frontmatter: f as LessonFrontmatter,
    test,
    verify,
    lab: fs.readFileSync(labPath, "utf8"),
  };
}

export function loadAllLessons(contentRoot: string) {
  const dirs = lessonDirs(contentRoot);
  const lessons = dirs.map((d) => parseLessonFolder(d, contentRoot));
  return lessons;
}

export function loadExams(contentRoot: string) {
  const examsDir = path.join(contentRoot, "exams");
  if (!fs.existsSync(examsDir)) return [];
  const out: { file: string; record: ExamRecord }[] = [];
  for (const f of fs.readdirSync(examsDir)) {
    if (!f.endsWith(".json")) continue;
    const raw = fs.readFileSync(path.join(examsDir, f), "utf8");
    const parsed = JSON.parse(raw);
    const v = EXAM_SCHEMA.safeParse(parsed);
    if (v.success) out.push({ file: f, record: v.data });
    else out.push({ file: f, record: parsed as ExamRecord });
  }
  return out;
}

export function validateExam(file: string, record: ExamRecord, expectedCount: number): ContentIssue[] {
  const issues: ContentIssue[] = [];
  const v = EXAM_SCHEMA.safeParse(record);
  if (!v.success) {
    for (const err of v.error.issues) issues.push({ path: file, message: err.message });
  }
  if (record.questions.length !== expectedCount) {
    issues.push({ path: file, message: `expected exactly ${expectedCount} questions, got ${record.questions.length}` });
  }
  record.questions.forEach((q, i) => {
    if (!TOPICS.includes(q.topic)) issues.push({ path: file, message: `question ${i}: unknown topic "${q.topic}"` });
  });
  return issues;
}

export function loadDrills(contentRoot: string): { drills: Drill[]; issues: ContentIssue[] } {
  const p = path.join(contentRoot, "drills.json");
  if (!fs.existsSync(p)) return { drills: [], issues: [{ path: "drills.json", message: "missing" }] };
  const parsed = JSON.parse(fs.readFileSync(p, "utf8"));
  const v = DRILLS_SCHEMA.safeParse(parsed);
  const issues: ContentIssue[] = [];
  if (!v.success) {
    for (const err of v.error.issues) issues.push({ path: "drills.json", message: err.message });
  }
  return { drills: (v.success ? v.data : parsed) as Drill[], issues };
}

export function collectCites(contentRoot: string): { lessonId: string; cite: Cite }[] {
  const out: { lessonId: string; cite: Cite }[] = [];
  for (const lesson of loadAllLessons(contentRoot)) {
    if (!lesson.frontmatter) continue;
    for (const cite of lesson.frontmatter.cites) {
      out.push({ lessonId: lesson.frontmatter.id, cite });
    }
  }
  return out;
}

export function topicIndexFor(lessons: { frontmatter: LessonFrontmatter | null; issues: ContentIssue[] }[]) {
  const index: Record<string, { id: string; slug: string; unitSlug: string; title: string }[]> = {};
  for (const l of lessons) {
    if (!l.frontmatter) continue;
    for (const t of l.frontmatter.topics) {
      (index[t] ??= []).push({
        id: l.frontmatter.id,
        slug: l.frontmatter.slug,
        unitSlug: l.frontmatter.unitSlug,
        title: l.frontmatter.title,
      });
    }
  }
  return index;
}