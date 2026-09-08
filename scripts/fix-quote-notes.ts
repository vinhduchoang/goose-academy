import fs from "node:fs";
import path from "node:path";
import { lessonDirs } from "../lib/content-io";
import { extractFrontmatter } from "../lib/fmparse";

function yamlSingleQuote(v: string): string {
  return "'" + v.replace(/'/g, "''") + "'";
}

function isQuoted(v: string): boolean {
  const t = v.trim();
  return (t.startsWith('"') && t.endsWith('"')) || (t.startsWith("'") && t.endsWith("'"));
}

function fixFrontmatter(fmText: string): { out: string; notesFixed: number } {
  let notesFixed = 0;
  const out = fmText
    .split(/\r?\n/)
    .map((line) => {
      const kv = line.match(/^(\s*(?:-\s*)?\w[-\w]*):\s*(.*)$/);
      if (!kv) return line;
      const [, keyPart, val] = kv;
      const key = keyPart.replace(/^\s*-?\s*/, "");
      if ((key === "note" || key === "title") && val.trim() !== "" && !isQuoted(val)) {
        notesFixed++;
        return `${keyPart}: ${yamlSingleQuote(val.trim())}`;
      }
      return line;
    })
    .join("\n");
  return { out, notesFixed };
}

function main(): number {
  const contentRoot = path.resolve(__dirname, "..", "content");
  const dirs = lessonDirs(contentRoot);
  let total = 0;
  for (const dir of dirs) {
    const p = path.join(dir, "lesson.mdx");
    const raw = fs.readFileSync(p, "utf8");
    const ex = extractFrontmatter(raw);
    if (!ex) {
      console.error(`no frontmatter: ${p}`);
      return 1;
    }
    const { out, notesFixed } = fixFrontmatter(ex.fmText);
    if (notesFixed > 0) {
      const newRaw = raw.replace(ex.fmText, out);
      fs.writeFileSync(p, newRaw, "utf8");
      total += notesFixed;
      console.log(`fixed ${notesFixed} scalar(s) in ${path.relative(process.cwd(), p)}`);
    }
  }
  console.log(`quote-fix total: ${total}`);
  return 0;
}

process.exit(main());