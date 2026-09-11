import type { MDXComponents } from "mdx/types";
import { codeToHtml } from "shiki";
import Link from "next/link";
import MermaidChart from "@/components/MermaidChart";

type CodeProps = React.HTMLAttributes<HTMLElement> & {
  children?: React.ReactNode;
};

function asText(node: React.ReactNode): string {
  if (node == null || typeof node === "boolean") return "";
  if (typeof node === "string" || typeof node === "number") return String(node);
  if (Array.isArray(node)) return node.map(asText).join("");
  if (typeof node === "object" && "props" in (node as { props?: unknown })) {
    return asText((node as { props: { children?: React.ReactNode } }).props.children);
  }
  return "";
}

async function Code({ className, children }: CodeProps) {
  const langMatch = className?.match(/language-([\w+-]+)/);
  const raw = asText(children);
  if (!langMatch || !raw.trim()) {
    return (
      <code className="rounded bg-zinc-200 px-1.5 py-0.5 font-mono text-[0.85em] text-zinc-800 dark:bg-zinc-800 dark:text-zinc-200">
        {raw}
      </code>
    );
  }
  const html = await codeToHtml(raw.replace(/\n$/, ""), {
    lang: langMatch[1],
    theme: "github-dark",
  });
  return (
    <div
      className="not-prose my-4 overflow-x-auto rounded-lg border border-zinc-800 bg-[#0d1117] text-sm [&_.shiki]:p-4 [&_.shiki]:!bg-transparent"
      dangerouslySetInnerHTML={{ __html: html }}
    />
  );
}

function Pre(props: React.HTMLAttributes<HTMLPreElement>) {
  return <pre {...props} />;
}

function FounderLens({ children }: { children?: React.ReactNode }) {
  return (
    <aside data-testid="founder-lens" className="my-6 rounded-lg border-l-4 border-amber-500 bg-amber-50 p-4 dark:bg-amber-950/40">
      <p className="mb-1 text-sm font-bold tracking-wide text-amber-700 uppercase dark:text-amber-400">
        Founder lens
      </p>
      <div className="text-sm text-zinc-800 dark:text-zinc-200">{children}</div>
    </aside>
  );
}

function MindShift({ children }: { children?: React.ReactNode }) {
  return (
    <aside data-testid="mind-shift" className="my-6 rounded-lg border-l-4 border-sky-500 bg-sky-50 p-4 dark:bg-sky-950/40">
      <p className="mb-1 text-sm font-bold tracking-wide text-sky-700 uppercase dark:text-sky-400">
        FE to Rust mind-shift
      </p>
      <div className="text-sm text-zinc-800 dark:text-zinc-200">{children}</div>
    </aside>
  );
}

function Diff({ oldCode, newCode }: { oldCode?: string; newCode?: string }) {
  const oldLines = (oldCode ?? "").split("\n");
  const newLines = (newCode ?? "").split("\n");
  return (
    <div data-testid="diff-view" className="not-prose my-4 overflow-x-auto rounded-lg border border-zinc-300 bg-zinc-50 font-mono text-xs leading-6 dark:border-zinc-700 dark:bg-zinc-900">
      {oldLines.map((l, i) => (
        <div key={`o${i}`} className="whitespace-pre bg-red-50 px-3 text-red-800 dark:bg-red-950/40 dark:text-red-300">
          {l.trim() === "" ? " " : `- ${l}`}
        </div>
      ))}
      {newLines.map((l, i) => (
        <div key={`n${i}`} className="whitespace-pre bg-green-50 px-3 text-green-800 dark:bg-green-950/40 dark:text-green-300">
          {l.trim() === "" ? " " : `+ ${l}`}
        </div>
      ))}
    </div>
  );
}

function CodeRunnerPrompt({ command, title }: { command?: string; title?: string }) {
  return (
    <div data-testid="code-runner" className="my-6 rounded-lg border border-zinc-300 bg-zinc-50 p-4 dark:border-zinc-700 dark:bg-zinc-900">
      <p className="mb-2 text-sm font-bold text-zinc-800 dark:text-zinc-200">
        {title ?? "Run this in your terminal"}
      </p>
      <pre className="overflow-x-auto rounded bg-zinc-900 p-3 font-mono text-xs text-zinc-100">{command}</pre>
    </div>
  );
}

const components = {
  h2: ({ children }: { children?: React.ReactNode }) => (
    <h2 className="mt-10 mb-4 border-b border-zinc-200 pb-1 text-2xl font-bold text-zinc-900 scroll-mt-20 dark:border-zinc-800 dark:text-zinc-100">
      {children}
    </h2>
  ),
  h3: ({ children }: { children?: React.ReactNode }) => (
    <h3 className="mt-8 mb-3 text-xl font-semibold text-zinc-900 scroll-mt-20 dark:text-zinc-100">
      {children}
    </h3>
  ),
  h4: ({ children }: { children?: React.ReactNode }) => (
    <h4 className="mt-6 mb-2 text-lg font-semibold text-zinc-900 dark:text-zinc-100">{children}</h4>
  ),
  a: ({ href, children }: React.AnchorHTMLAttributes<HTMLAnchorElement> & { children?: React.ReactNode }) => {
    if (href?.startsWith("/") || href?.startsWith("#")) {
      return <Link href={href} className="font-medium text-sky-600 underline decoration-sky-600/30 underline-offset-2 hover:text-sky-500 dark:text-sky-400">{children}</Link>;
    }
    return (
      <a href={href} target="_blank" rel="noreferrer" className="font-medium text-sky-600 underline decoration-sky-600/30 underline-offset-2 hover:text-sky-500 dark:text-sky-400">
        {children}
      </a>
    );
  },
  blockquote: ({ children }: { children?: React.ReactNode }) => (
    <blockquote className="my-4 border-l-4 border-zinc-300 pl-4 text-zinc-600 italic dark:border-zinc-600 dark:text-zinc-400">
      {children}
    </blockquote>
  ),
  ul: ({ children }: { children?: React.ReactNode }) => <ul className="my-4 list-disc space-y-1.5 pl-6">{children}</ul>,
  ol: ({ children }: { children?: React.ReactNode }) => <ol className="my-4 list-decimal space-y-1.5 pl-6">{children}</ol>,
  li: ({ children }: { children?: React.ReactNode }) => <li className="text-zinc-800 dark:text-zinc-200">{children}</li>,
  table: ({ children }: { children?: React.ReactNode }) => (
    <div className="my-6 overflow-x-auto rounded-lg border border-zinc-200 dark:border-zinc-700">
      <table className="min-w-full divide-y divide-zinc-200 text-sm dark:divide-zinc-700">{children}</table>
    </div>
  ),
  th: ({ children }: { children?: React.ReactNode }) => (
    <th className="bg-zinc-50 px-3 py-2 text-left font-semibold text-zinc-900 dark:bg-zinc-800 dark:text-zinc-100">{children}</th>
  ),
  td: ({ children }: { children?: React.ReactNode }) => (
    <td className="px-3 py-2 align-top text-zinc-700 dark:text-zinc-300">{children}</td>
  ),
  hr: () => <hr className="my-8 border-zinc-200 dark:border-zinc-700" />,
  code: Code,
  pre: Pre,
  FounderLens,
  MindShift,
  Diff,
  CodeRunnerPrompt,
  Mermaid: ({ chart, title }: { chart?: string; title?: string }) => (
    <MermaidChart chart={chart} title={title} />
  ),
} as MDXComponents;

export function useMDXComponents(): MDXComponents {
  return components;
}