import { notFound } from "next/navigation";
import Link from "next/link";
import { ExamClient } from "@/components/ExamClient";
import { UNITS, exams, lessonsForUnit } from "@/content/manifest";

export function generateStaticParams() {
  return exams.map((e) => ({ unit: e.unitSlug }));
}

export const dynamicParams = false;

export default async function Page({ params }: { params: Promise<{ unit: string }> }) {
  const { unit } = await params;
  const exam = exams.find((e) => e.unitSlug === unit);
  if (!exam) notFound();
  const unitMeta = UNITS.find((u) => u.slug === unit);

  const ls = lessonsForUnit(unit).map((l) => ({
    id: l.id,
    slug: l.slug,
    unitIndex: l.unitIndex,
    unitSlug: l.unitSlug,
    order: l.order,
    title: l.title,
    topics: l.topics,
    cites: l.cites,
    durationMin: l.durationMin,
  }));

  return (
    <div className="space-y-6">
      <Link href={`/units/${unit}`} className="text-sm text-zinc-500 hover:text-zinc-800 dark:hover:text-zinc-200">
        ← Unit {unitMeta?.index}
      </Link>
      <ExamClient exam={exam} lessons={ls} />
    </div>
  );
}