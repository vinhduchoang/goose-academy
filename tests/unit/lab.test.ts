import { describe, expect, it } from "vitest";
import { generateVerifyScript, parseVerifyVerdict } from "@/lib/lab";

describe("TC-LB-01 verify.ps1 generator", () => {
  it("emits a PS5.1 script with checks and verdict", () => {
    const script = generateVerifyScript("u0-l01", "Toolchain", [
      { kind: "file-exists", name: "has Justfile", detail: "missing", path: "Justfile" },
      { kind: "notes-exists", name: "notes file", detail: "create lab01-notes.md", path: "lab01-notes.md" },
    ]);
    expect(script).toContain("VERIFY PASSED");
    expect(script).toContain("exit 0");
    expect(script).toContain("VERIFY FAILED");
    expect(script).toContain("exit 1");
    expect(script).toContain("Justfile");
    expect(script).toContain("lab01-notes.md");
  });
  it("escapes paths with backslashes", () => {
    const script = generateVerifyScript("u0-l01", "T", [
      { kind: "content-match", name: "c", detail: "d", path: "crates\\goose\\src\\lib.rs", pattern: 'x = "y"' },
    ]);
    expect(script).toContain("crates\\\\goose\\\\src\\\\lib.rs");
  });
});

describe("TC-LB-02 verdict marker parsing", () => {
  it("passes when all markers present", () => {
    const v = parseVerifyVerdict("VERIFY PASSED 5/5\nstruct present\n", [
      "VERIFY PASSED",
      "struct present",
    ]);
    expect(v.passed).toBe(true);
    expect(v.missing).toHaveLength(0);
  });
  it("fails and lists missing markers", () => {
    const v = parseVerifyVerdict("VERIFY PASSED 4/5", [
      "VERIFY PASSED",
      "async fn stream present",
    ]);
    expect(v.passed).toBe(false);
    expect(v.missing).toEqual(["async fn stream present"]);
  });
});