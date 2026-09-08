import fs from "node:fs";
import path from "node:path";
import { checkDrift, extractWorkspaceVersion } from "../lib/drift";
import { collectCites } from "../lib/content-io";

function main(): number {
  const repoArg = process.argv[2] ?? process.env.GOOSE_REPO;
  if (!repoArg) {
    console.error("usage: pnpm drift <path-to-goose-checkout>  (or set GOOSE_REPO)");
    return 2;
  }
  const root = path.resolve(repoArg);
  if (!fs.existsSync(path.join(root, "Cargo.toml"))) {
    console.error(`DRIFT: ${root} does not look like a goose checkout (no Cargo.toml)`);
    return 2;
  }
  const readFile = (p: string) => {
    try {
      if (!fs.lstatSync(path.join(root, p)).isFile()) return null;
      return fs.readFileSync(path.join(root, p), "utf8");
    } catch {
      return null;
    }
  };
  const version = extractWorkspaceVersion(readFile("Cargo.toml"));
  const contentRoot = path.resolve(
    process.env.GOOSE_CONTENT_DIR ?? path.join(__dirname, "..", "content")
  );
  const cites = collectCites(contentRoot);
  const { issues, versionIssue } = checkDrift(
    cites,
    { readFile, version },
    { requirePinnedVersion: process.env.GOOSE_ALLOW_REVISION !== "1" }
  );

  console.log(`DRIFT CHECK — ${cites.length} citations against ${root} (workspace version: ${version ?? "unknown"})`);
  if (versionIssue) {
    console.error(`  [WRONG-VERSION] checkout version ${version} does not match pinned ${"1.49.0"}`);
  }
  for (const i of issues) {
    console.error(`  [${i.reason}] ${i.lessonId}: ${i.file}:${i.line}`);
  }
  if (issues.length === 0 && !versionIssue) {
    console.log("DRIFT OK");
    return 0;
  }
  return 1;
}

process.exit(main());