import fs from "node:fs";
import path from "node:path";
import { notFound } from "next/navigation";
import Link from "next/link";
import { LessonPageClient } from "@/components/LessonPageClient";
import { lessonByRoute, lessonsForUnit, UNITS } from "@/content/manifest";

export function generateStaticParams() {
  const out: { slug: string; lesson: string }[] = [];
  for (const u of UNITS) {
    for (const l of lessonsForUnit(u.slug)) out.push({ slug: u.slug, lesson: l.slug });
  }
  return out;
}

export const dynamicParams = false;

export default async function Page({
  params,
}: {
  params: Promise<{ slug: string; lesson: string }>;
}) {
  const { slug, lesson: lessonSlug } = await params;
  const lesson = lessonByRoute(slug, lessonSlug);
  if (!lesson) notFound();

  const unitLessons = lessonsForUnit(slug);
  const idx = unitLessons.findIndex((l) => l.id === lesson.id);
  const prev = idx > 0 ? unitLessons[idx - 1] : null;
  const next = idx >= 0 && idx < unitLessons.length - 1 ? unitLessons[idx + 1] : null;

  const contentRoot = path.resolve(process.cwd(), "content");
  const verifyPath = path.join(contentRoot, "units", `u${lesson.unitIndex}`, lesson.id.split("-")[1], "verify.ps1");
  const verifyScript = fs.readFileSync(verifyPath, "utf8");

  const meta = {
    id: lesson.id,
    slug: lesson.slug,
    unitIndex: lesson.unitIndex,
    unitSlug: lesson.unitSlug,
    order: lesson.order,
    title: lesson.title,
    topics: lesson.topics,
    cites: lesson.cites,
    durationMin: lesson.durationMin,
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between text-sm">
        <Link href={`/units/${slug}`} className="text-zinc-500 hover:text-zinc-800 dark:hover:text-zinc-200">
          ← Unit {lesson.unitIndex}
        </Link>
        <div className="space-y-1 text-right">
          {lesson.cites.map((c, i) => (
            <p key={i} className="font-mono text-xs text-zinc-500">
              {c.file}:{c.line} — {c.note}
            </p>
          ))}
        </div>
      </div>
      <LessonPageClient
        lesson={meta}
        theory={<lesson.Lesson />}
        lab={<lesson.Lab />}
        test={lesson.test}
        verifyScript={verifyScript}
        prev={prev ? { title: prev.title, slug: prev.slug } : null}
        next={next ? { title: next.title, slug: next.slug } : null}
      />
    </div>
  );
}