import { ReportClient } from "@/components/ReportClient";
import { drills, topicIndex } from "@/content/manifest";

export default function Page() {
  const index = structuredClone(topicIndex) as Record<
    string,
    {
      id: string;
      slug: string;
      unitIndex: number;
      unitSlug: string;
      order: number;
      title: string;
      topics: string[];
      cites: { file: string; line: number; note?: string }[];
      durationMin: number;
    }[]
  >;
  return <ReportClient topicIndex={index} drills={drills} />;
}