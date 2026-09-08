import fs from "node:fs";
import path from "node:path";
import {
  loadAllLessons,
  loadDrills,
  loadExams,
  validateExam,
} from "../lib/content-io";
import { generateManifest } from "./generate-manifest";
import { TOPICS } from "../lib/schema";

const CONTENT_ROOT = path.resolve(__dirname, "..", "content");
const MANIFEST_PATH = path.join(CONTENT_ROOT, "manifest.ts");

function main(): number {
  const all: { path: string; message: string }[] = [];
  const unitSlugMap: Record<number, string> = {
    0: "rust-core",
    1: "architecture",
    2: "core-contribution",
    3: "extensions",
  };

  const lessons = loadAllLessons(CONTENT_ROOT);
  if (lessons.length !== 46) {
    all.push({ path: "content/units", message: `expected 46 lessons, found ${lessons.length}` });
  }
  const ids = new Set<string>();
  const routeSlugs = new Set<string>();
  const titles: Record<number, string[]> = { 0: [], 1: [], 2: [], 3: [] };
  for (const l of lessons) {
    all.push(...l.issues.map((i) => ({ path: i.path, message: i.message })));
    if (!l.frontmatter) continue;
    const fm = l.frontmatter;
    if (ids.has(fm.id)) all.push({ path: `${fm.id}`, message: "duplicate lesson id" });
    ids.add(fm.id);
    const route = `${fm.unitSlug}/${fm.slug}`;
    if (routeSlugs.has(route)) all.push({ path: `${fm.id}`, message: `duplicate route slug ${route}` });
    routeSlugs.add(route);
    titles[fm.unit]?.push(fm.slug);
    if (unitSlugMap[fm.unit] !== fm.unitSlug) {
      all.push({ path: `${fm.id}`, message: `unit ${fm.unit} must use unitSlug ${unitSlugMap[fm.unit]}` });
    }
    if (fm.order < 1 || fm.order > 15) {
      all.push({ path: `${fm.id}`, message: `order out of range: ${fm.order}` });
    }
    if (fm.topics.length === 0) all.push({ path: `${fm.id}`, message: "no topics" });
    for (const t of fm.topics) {
      if (!TOPICS.includes(t)) all.push({ path: `${fm.id}`, message: `unknown topic "${t}"` });
    }
  }

  const [u0, u1, u2, u3] = [
    titles[0].length,
    titles[1].length,
    titles[2].length,
    titles[3].length,
  ];
  if (u0 !== 15 || u1 !== 11 || u2 !== 10 || u3 !== 10) {
    all.push({
      path: "content/units",
      message: `lesson count per unit wrong: u0=${u0} u1=${u1} u2=${u2} u3=${u3}`,
    });
  }

  const exams = loadExams(CONTENT_ROOT);
  const expectedCounts: Record<string, number> = { "u0.json": 25, "u1.json": 25, "u2.json": 25, "u3.json": 40 };
  if (exams.length !== 4) {
    all.push({ path: "content/exams", message: `expected 4 exams, found ${exams.length}` });
  }
  for (const { file, record } of exams) {
    const expected = expectedCounts[file];
    if (expected === undefined) {
      all.push({ path: file, message: "unknown exam file name" });
      continue;
    }
    all.push(...validateExam(file, record, expected).map((i) => ({ path: i.path, message: i.message })));
    const unitExams = exams.filter((e) => e.file !== file);
    if (unitExams.some((e) => e.record.unitSlug === record.unitSlug)) {
      all.push({ path: file, message: `duplicate exam unitSlug ${record.unitSlug}` });
    }
  }

  const { drills, issues: drillIssues } = loadDrills(CONTENT_ROOT);
  all.push(...drillIssues.map((i) => ({ path: i.path, message: i.message })));
  const drillTopics = new Set(drills.map((d) => d.topic));
  const lessonTopics = new Set(lessons.flatMap((l) => (l.frontmatter ? l.frontmatter.topics : [])));
  for (const t of drillTopics) {
    if (!TOPICS.includes(t)) all.push({ path: "drills.json", message: `unknown topic "${t}"` });
  }
  const orphanDrillTopics = [...drillTopics].filter((t) => !lessonTopics.has(t));
  if (orphanDrillTopics.length > 0) {
    all.push({
      path: "drills.json",
      message: `drills reference topics no lesson teaches: ${orphanDrillTopics.join(", ")}`,
    });
  }

  const manifest = generateManifest();
  const onDisk = fs.existsSync(MANIFEST_PATH)
    ? fs.readFileSync(MANIFEST_PATH, "utf8")
    : null;
  if (onDisk !== manifest) {
    fs.writeFileSync(MANIFEST_PATH, manifest, "utf8");
    all.push({
      path: "content/manifest.ts",
      message: "manifest was stale — regenerated. Re-run the gate.",
    });
  }

  if (all.length > 0) {
    console.error(`VERIFY CONTENT FAILED — ${all.length} issue(s):`);
    for (const i of all.slice(0, 50)) {
      console.error(`  ${i.path}: ${i.message}`);
    }
    if (all.length > 50) console.error(`  ...and ${all.length - 50} more`);
    return 1;
  }
  console.log(
    `VERIFY CONTENT OK — ${lessons.length} lessons, ${exams.length} exams, ${drills.length} drills, ${TOPICS.length} topics`
  );
  return 0;
}

process.exit(main());