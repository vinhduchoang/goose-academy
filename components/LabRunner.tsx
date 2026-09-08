"use client";

import { useState } from "react";
import { useProgress } from "@/components/ProgressProvider";
import { markLabVerified, lessonAccessor } from "@/lib/progress";
import { VerifyGenerator } from "@/components/VerifyGenerator";

export function LabRunner({
  lessonId,
  verifyScript,
}: {
  lessonId: string;
  verifyScript: string;
}) {
  const { progress, update } = useProgress();
  const verified = lessonAccessor(progress, lessonId).labVerified;
  const [copied, setCopied] = useState(false);

  async function copy() {
    try {
      await navigator.clipboard.writeText(verifyScript);
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch {
      setCopied(false);
    }
  }

  function download() {
    const blob = new Blob([verifyScript], { type: "text/plain" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "verify.ps1";
    a.click();
    URL.revokeObjectURL(url);
  }

  return (
    <div data-testid="lab-runner" className="space-y-4">
      <div className="rounded-lg border border-zinc-200 bg-white p-4 dark:border-zinc-700 dark:bg-zinc-900">
        <p className="mb-2 text-sm font-semibold">Step 4 — verify your lab</p>
        <p className="mb-3 text-xs text-zinc-600 dark:text-zinc-400">
          In PowerShell, cd to your lab dir and run{" "}
          <code className="rounded bg-zinc-100 px-1 py-0.5 font-mono dark:bg-zinc-800">
            .\verify.ps1
          </code>{" "}
          from the lesson folder (download below), or copy it.
        </p>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={copy}
            className="rounded-md border border-zinc-300 px-3 py-1.5 text-sm hover:bg-zinc-100 dark:border-zinc-600 dark:hover:bg-zinc-800"
          >
            {copied ? "Copied" : "Copy script"}
          </button>
          <button
            type="button"
            onClick={download}
            className="rounded-md border border-zinc-300 px-3 py-1.5 text-sm hover:bg-zinc-100 dark:border-zinc-600 dark:hover:bg-zinc-800"
          >
            Download verify.ps1
          </button>
        </div>
        <pre className="mt-3 max-h-64 overflow-auto rounded bg-zinc-950 p-3 font-mono text-xs text-zinc-100">
          {verifyScript}
        </pre>
      </div>

      <div data-testid="lab-verify-toggle" className="rounded-lg border border-zinc-200 bg-white p-4 dark:border-zinc-700 dark:bg-zinc-900">
        <label className="flex cursor-pointer items-start gap-3">
          <input
            type="checkbox"
            checked={verified}
            onChange={(e) => {
              if (e.target.checked) {
                update((p) => markLabVerified(p, lessonId, Date.now()));
              }
            }}
            className="mt-0.5 h-4 w-4 accent-emerald-600"
          />
          <span className="text-sm">
            <span className="font-semibold">Lab verified</span>
            <span className="block text-xs text-zinc-600 dark:text-zinc-400">
              I ran the steps under the repo pinned goose v1.49.0 and my verify output ended with{" "}
              <code className="rounded bg-zinc-100 px-1 font-mono dark:bg-zinc-800">VERIFY PASSED</code>.
              {" "}Once the test score is ≥ 80 too, the lesson is complete.
            </span>
          </span>
        </label>
      </div>

      <VerifyGenerator />
    </div>
  );
}