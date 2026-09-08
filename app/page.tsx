import { DashboardClient } from "@/components/DashboardClient";
import { UNITS, lessons, unitLessonCount } from "@/content/manifest";

export default function Page() {
  const units = UNITS.map((u) => ({
    index: u.index,
    slug: u.slug,
    title: u.title,
    tagline: u.tagline,
    lessonCount: unitLessonCount[u.slug] ?? 0,
  })).sort((a, b) => a.index - b.index);

  const meta = lessons.map((l) => ({
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

  return <DashboardClient units={units} lessons={meta} />;
}