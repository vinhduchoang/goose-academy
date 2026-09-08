import { DrillsClient } from "@/components/DrillsClient";
import { drills } from "@/content/manifest";

export default async function Page({
  searchParams,
}: {
  searchParams: Promise<{ topic?: string }>;
}) {
  const { topic } = await searchParams;
  const initialTopic = topic && drills.some((d) => d.topic === topic) ? topic : null;
  return <DrillsClient drills={drills} initialTopic={initialTopic} />;
}