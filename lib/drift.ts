import type { Cite } from "@/lib/types";

export const PINNED_GOOSE_VERSION = "1.49.0";

export interface CiteRef {
  lessonId: string;
  cite: Cite;
}

export interface DriftRepo {
  readFile(path: string): string | null;
  version: string | null;
}

export interface DriftIssue {
  lessonId: string;
  file: string;
  line: number;
  reason: "missing-file" | "line-out-of-range" | "wrong-version";
}

export function checkDrift(
  cites: CiteRef[],
  repo: DriftRepo,
  opts: { requirePinnedVersion?: boolean } = {}
): { issues: DriftIssue[]; versionIssue: boolean } {
  const issues: DriftIssue[] = [];
  const versionIssue =
    opts.requirePinnedVersion === true && repo.version !== PINNED_GOOSE_VERSION;
  for (const { lessonId, cite } of cites) {
    const content = repo.readFile(cite.file);
    if (content === null) {
      issues.push({
        lessonId,
        file: cite.file,
        line: cite.line,
        reason: "missing-file",
      });
      continue;
    }
    const lineCount = content.split("\n").length;
    if (content.length > 0 && lineCount < cite.line) {
      issues.push({
        lessonId,
        file: cite.file,
        line: cite.line,
        reason: "line-out-of-range",
      });
    }
  }
  return { issues, versionIssue };
}

export function extractWorkspaceVersion(cargoToml: string | null): string | null {
  if (!cargoToml) return null;
  const m = cargoToml.match(/^\[workspace\.package\][\s\S]*?^version\s*=\s*"([^"]+)"/m);
  return m ? m[1] : null;
}