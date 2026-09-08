"use client";

import { useState } from "react";
import { CheckSpec, generateVerifyScript } from "@/lib/lab";

const PRESETS: { name: string; kind: CheckSpec["kind"]; placeholder: string }[] = [
  { name: "Goose file exists", kind: "file-exists", placeholder: "crates/goose/Cargo.toml" },
  { name: "File content matches", kind: "content-match", placeholder: "Cargo.toml" },
  { name: "Learner artifacts exist", kind: "notes-exists", placeholder: "notes.md" },
  { name: "Workspace member present", kind: "cargo-metadata", placeholder: "goose" },
];

export function VerifyGenerator() {
  const [checks, setChecks] = useState<CheckSpec[]>([]);
  const [output, setOutput] = useState<string | null>(null);

  function add() {
    setChecks((prev) => [
      ...prev,
      { name: "", kind: "content-match", detail: "", path: "", pattern: "" },
    ]);
  }

  function patch(i: number, patch: Partial<CheckSpec>) {
    setChecks((prev) => prev.map((c, idx) => (idx === i ? { ...c, ...patch } : c)));
  }

  function remove(i: number) {
    setChecks((prev) => prev.filter((_, idx) => idx !== i));
  }

  function generate() {
    const valid = checks
      .map((c) => ({ ...c, name: c.name || `check-${checks.indexOf(c) + 1}`, detail: c.detail || "see lab", path: c.path || "", pattern: c.pattern || "" }))
      .filter((c) => (c.kind === "cargo-metadata" ? true : c.path.length > 0));
    setOutput(generateVerifyScript("custom", "Custom lab", valid));
  }

  return (
    <div data-testid="verify-generator" className="rounded-lg border border-zinc-200 bg-white p-4 dark:border-zinc-700 dark:bg-zinc-900">
      <p className="mb-3 text-sm font-semibold">Generate your own verify.ps1</p>
      <div className="space-y-3">
        {checks.map((c, i) => (
          <div key={i} className="flex flex-wrap items-center gap-2 text-sm">
            <select
              aria-label="check kind"
              value={c.kind}
              onChange={(e) => patch(i, { kind: e.target.value as CheckSpec["kind"] })}
              className="rounded border border-zinc-300 bg-white px-2 py-1 dark:border-zinc-600 dark:bg-zinc-800"
            >
              {PRESETS.map((p) => (
                <option key={p.kind} value={p.kind}>
                  {p.name}
                </option>
              ))}
            </select>
            <input
              aria-label="check name"
              placeholder="check name"
              value={c.name}
              onChange={(e) => patch(i, { name: e.target.value })}
              className="w-40 rounded border border-zinc-300 bg-white px-2 py-1 dark:border-zinc-600 dark:bg-zinc-800"
            />
            {c.kind !== "cargo-metadata" ? (
              <input
                aria-label="check path"
                placeholder={PRESETS.find((p) => p.kind === c.kind)?.placeholder}
                value={c.path ?? ""}
                onChange={(e) => patch(i, { path: e.target.value })}
                className="w-56 rounded border border-zinc-300 bg-white px-2 py-1 dark:border-zinc-600 dark:bg-zinc-800"
              />
            ) : (
              <input
                aria-label="member name"
                placeholder="member name"
                value={c.pattern ?? ""}
                onChange={(e) => patch(i, { pattern: e.target.value })}
                className="w-40 rounded border border-zinc-300 bg-white px-2 py-1 dark:border-zinc-600 dark:bg-zinc-800"
              />
            )}
            {c.kind === "content-match" && (
              <input
                aria-label="match pattern"
                placeholder="regex pattern"
                value={c.pattern ?? ""}
                onChange={(e) => patch(i, { pattern: e.target.value })}
                className="w-48 rounded border border-zinc-300 bg-white px-2 py-1 font-mono text-xs dark:border-zinc-600 dark:bg-zinc-800"
              />
            )}
            <button
              type="button"
              onClick={() => remove(i)}
              className="rounded border border-zinc-300 px-2 py-1 text-xs text-red-600 hover:bg-red-50 dark:border-zinc-600"
            >
              remove
            </button>
          </div>
        ))}
      </div>
      <div className="mt-3 flex gap-2">
        <button
          type="button"
          onClick={add}
          className="rounded-md border border-zinc-300 px-3 py-1.5 text-sm hover:bg-zinc-100 dark:border-zinc-600 dark:hover:bg-zinc-800"
        >
          + Add check
        </button>
        <button
          type="button"
          onClick={generate}
          className="rounded-md bg-zinc-800 px-3 py-1.5 text-sm font-semibold text-white hover:bg-zinc-700 dark:bg-zinc-200 dark:text-zinc-900 dark:hover:bg-zinc-300"
        >
          Generate
        </button>
      </div>
      {output && (
        <pre data-testid="generated-script" className="mt-3 max-h-72 overflow-auto rounded bg-zinc-950 p-3 font-mono text-xs text-zinc-100">
          {output}
        </pre>
      )}
    </div>
  );
}