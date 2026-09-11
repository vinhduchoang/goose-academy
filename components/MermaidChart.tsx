"use client";

import { useEffect, useRef, useState } from "react";

export default function MermaidChart({ chart, title }: { chart?: string; title?: string }) {
  const ref = useRef<HTMLDivElement>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!chart) return;
    const source = chart;
    let alive = true;
    async function render() {
      try {
        const { default: mermaid } = await import("mermaid");
        mermaid.initialize({ startOnLoad: false, theme: "default", securityLevel: "strict" });
        const id = `mma-${Math.random().toString(36).slice(2, 10)}`;
        const { svg } = await mermaid.render(id, source);
        if (alive && ref.current) ref.current.innerHTML = svg;
      } catch (e) {
        if (alive) setError(e instanceof Error ? e.message : String(e));
      }
    }
    void render();
    return () => {
      alive = false;
    };
  }, [chart]);

  return (
    <figure
      data-testid="mermaid-chart"
      className="not-prose my-6 rounded-lg border border-zinc-200 bg-white p-4 dark:border-zinc-700 dark:bg-zinc-900"
    >
      {title ? (
        <figcaption className="mb-3 text-sm font-semibold text-zinc-700 dark:text-zinc-300">
          {title}
        </figcaption>
      ) : null}
      {error ? (
        <pre className="overflow-x-auto rounded bg-zinc-900 p-3 font-mono text-xs text-red-300">
          {chart}
          {"\n--- render error ---\n"}
          {error}
        </pre>
      ) : (
        <div ref={ref} className="flex justify-center overflow-x-auto [&_svg]:max-w-full" />
      )}
    </figure>
  );
}