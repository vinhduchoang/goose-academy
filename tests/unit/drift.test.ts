import { describe, expect, it } from "vitest";
import { checkDrift, extractWorkspaceVersion, PINNED_GOOSE_VERSION } from "@/lib/drift";
import type { CiteRef, DriftRepo } from "@/lib/drift";

function repo(files: Record<string, string | null>, version: string | null): DriftRepo {
  return {
    version,
    readFile: (p: string) => (p in files ? files[p] : null),
  };
}

const cites: CiteRef[] = [
  { lessonId: "u0-l01", cite: { file: "Cargo.toml", line: 7 } },
  { lessonId: "u1-l02", cite: { file: "crates/goose/src/lib.rs", line: 10 } },
  { lessonId: "u1-l03", cite: { file: "crates/gone.rs", line: 3 } },
];

describe("TC-DR-01 missing file flagged", () => {
  it("flags citations whose file does not exist", () => {
    const { issues } = checkDrift(cites, repo({ "Cargo.toml": "a\nb", "crates/goose/src/lib.rs": "x" }, null), {});
    expect(issues).toContainEqual({
      lessonId: "u1-l03",
      file: "crates/gone.rs",
      line: 3,
      reason: "missing-file",
    });
  });
});

describe("TC-DR-02 line out of range flagged", () => {
  it("flags citations past the end of file", () => {
    const { issues } = checkDrift(
      cites,
      repo({ "Cargo.toml": "a\nb", "crates/goose/src/lib.rs": "x" }, null),
      {}
    );
    expect(issues).toContainEqual({
      lessonId: "u1-l02",
      file: "crates/goose/src/lib.rs",
      line: 10,
      reason: "line-out-of-range",
    });
  });
  it("line 1 of 3-line file passes", () => {
    const one = [{ lessonId: "x", cite: { file: "f", line: 1 } }];
    // "a\nb\nc" has 3 lines
    const { issues } = checkDrift(one, repo({ f: "a\nb\nc" }, null), {});
    expect(issues).toHaveLength(0);
  });
});

describe("TC-DR-03 wrong version gate", () => {
  it("flags when checkout is not the pinned version", () => {
    const r = repo({ "Cargo.toml": "x" }, "1.50.0");
    const { versionIssue } = checkDrift([], r, { requirePinnedVersion: true });
    expect(versionIssue).toBe(true);
    const r2 = repo({ "Cargo.toml": "x" }, PINNED_GOOSE_VERSION);
    expect(checkDrift([], r2, { requirePinnedVersion: true }).versionIssue).toBe(false);
  });
  it("extracts workspace version from Cargo.toml", () => {
    expect(
      extractWorkspaceVersion(
        '[workspace]\nmembers = ["crates/*"]\n[workspace.package]\nedition = "2021"\nversion = "1.49.0"\n'
      )
    ).toBe("1.49.0");
    expect(extractWorkspaceVersion(null)).toBeNull();
  });
});

describe("TC-DR-04 clean repo passes", () => {
  it("no issues on exact checkout", () => {
    const { issues } = checkDrift(
      cites,
      repo({ "Cargo.toml": "\n".repeat(7), "crates/goose/src/lib.rs": "\n".repeat(10), "crates/gone.rs": "\n".repeat(3) + "x" }, PINNED_GOOSE_VERSION),
      { requirePinnedVersion: true }
    );
    expect(issues).toHaveLength(0);
  });
});