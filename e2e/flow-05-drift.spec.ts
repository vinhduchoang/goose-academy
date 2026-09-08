import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { expect, test } from "@playwright/test";

function makeFixture(contentOverrides: { ok: boolean }) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "goose-academy-drift-"));
  const fixtureContent = path.join(root, "content");
  const fixtureRepo = path.join(root, "repo");
  fs.mkdirSync(fixtureContent, { recursive: true });
  fs.mkdirSync(path.join(fixtureContent, "units", "u0", "l01"), { recursive: true });
  fs.mkdirSync(fixtureRepo, { recursive: true });
  fs.writeFileSync(
    path.join(fixtureRepo, "Cargo.toml"),
    '[workspace]\nmembers = ["crates/*"]\n[workspace.package]\nversion = "1.49.0"\n'
  );
  fs.writeFileSync(
    path.join(fixtureContent, "units", "u0", "l01", "lesson.mdx"),
    [
      "---",
      "unit: 0",
      "unitSlug: rust-core",
      "order: 1",
      "id: u0-l01",
      "slug: 01-fixture",
      "title: Fixture lesson",
      "topics: [cargo]",
      "durationMin: 20",
      "cites:",
      "  - file: Cargo.toml",
      "    line: 2",
      contentOverrides.ok
        ? "    note: workspace members"
        : '    note: "broken cite"',
      contentOverrides.ok ? "  - file: Cargo.toml" : "  - file: MISSING_FILE.rs",
      "    line: 3",
      "---",
      "",
      "# Fixture",
      "",
      "Enough theory body text to pass the minimum length check in the checker.",
    ].join("\n")
  );
  fs.writeFileSync(
    path.join(fixtureContent, "units", "u0", "l01", "lab.md"),
    "# Lab\n\n## Verification\n\nRun verify.ps1.\n\n## Homework\n\nNote your answer."
  );
  fs.writeFileSync(path.join(fixtureContent, "units", "u0", "l01", "verify.ps1"), "VERIFY PASSED 1/1\nexit 0\n");
  fs.writeFileSync(
    path.join(fixtureContent, "units", "u0", "l01", "test.json"),
    JSON.stringify([
      {
        q: "q",
        options: ["a", "b", "c", "d"],
        answer: 0,
        topic: "cargo",
        explanation: ["1", "2", "3"],
      },
    ])
  );
  fs.writeFileSync(
    path.join(fixtureContent, "topics.json"),
    JSON.stringify({ version: 1, topics: ["cargo"] })
  );
  return { root, fixtureContent, fixtureRepo };
}

function runDrift(fixtureContent: string, fixtureRepo: string): { status: number; stdout: string; stderr: string } {
  try {
    const stdout = execFileSync("node", ["node_modules/tsx/dist/cli.mjs", "scripts/check-drift.ts"], {
      cwd: process.cwd(),
      env: {
        ...process.env,
        GOOSE_CONTENT_DIR: fixtureContent,
        GOOSE_REPO: fixtureRepo,
        GOOSE_ALLOW_REVISION: "0",
      },
      stdio: ["ignore", "pipe", "pipe"],
    });
    return { status: 0, stdout: String(stdout), stderr: "" };
  } catch (e) {
    const err = e as { status?: number; stdout?: string | Buffer; stderr?: string | Buffer };
    return {
      status: err.status ?? 1,
      stdout: String(err.stdout ?? ""),
      stderr: String(err.stderr ?? ""),
    };
  }
}

function outputOf(r: { stdout: string; stderr: string }): string {
  return `${r.stdout}\n${r.stderr}`;
}

test("TC-E2E-05a drift checker flags broken citation", async () => {
  const f = makeFixture({ ok: false });
  try {
    const r = runDrift(f.fixtureContent, f.fixtureRepo);
    expect(r.status, `output: ${outputOf(r)}`).toBe(1);
    expect(outputOf(r)).toContain("[missing-file]");
  } finally {
    fs.rmSync(f.root, { recursive: true, force: true });
  }
});

test("TC-E2E-05b drift checker passes a clean set of citations", async () => {
  const f = makeFixture({ ok: true });
  try {
    const r = runDrift(f.fixtureContent, f.fixtureRepo);
    expect(r.status, `output: ${outputOf(r)}`).toBe(0);
    expect(outputOf(r)).toContain("DRIFT OK");
  } finally {
    fs.rmSync(f.root, { recursive: true, force: true });
  }
});
