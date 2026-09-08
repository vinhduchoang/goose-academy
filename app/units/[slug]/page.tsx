import { notFound } from "next/navigation";
import Link from "next/link";
import { UnitOverviewClient } from "@/components/UnitOverviewClient";
import { UNITS, lessonsForUnit, unitLessonCount } from "@/content/manifest";

export function generateStaticParams() {
  return UNITS.map((u) => ({ slug: u.slug }));
}

export const dynamicParams = false;

export default async function Page({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const unit = UNITS.find((u) => u.slug === slug);
  if (!unit) notFound();
  const ls = lessonsForUnit(slug);

  const meta = ls.map((l) => ({
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
      <Link href="/" className="text-sm text-zinc-500 hover:text-zinc-800 dark:hover:text-zinc-200">
        ← Dashboard
      </Link>
      <UnitOverviewClient
        unit={{ ...unit, lessonCount: unitLessonCount[slug] ?? ls.length }}
        lessons={meta}
      />
    </div>
  );
}