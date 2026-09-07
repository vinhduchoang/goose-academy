export interface ParsedFrontmatter {
  data: Record<string, unknown>;
  content: string;
}

function stripQuotes(v: string): string {
  const t = v.trim();
  if (
    (t.startsWith('"') && t.endsWith('"')) ||
    (t.startsWith("'") && t.endsWith("'"))
  ) {
    const inner = t.slice(1, -1);
    return t.startsWith('"') ? inner.replace(/\\"/g, '"') : inner.replace(/''/g, "'");
  }
  return t;
}

function scalar(v: string): string | number | boolean {
  const t = v.trim();
  if (/^-?\d+$/.test(t)) return Number(t);
  if (t === "true") return true;
  if (t === "false") return false;
  return stripQuotes(t);
}

export function extractFrontmatter(raw: string): { fmText: string; content: string } | null {
  const m = raw.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n?/);
  if (!m) return null;
  return { fmText: m[1], content: raw.slice(m[0].length) };
}

enum Section {
  None = 0,
  Cites = 1,
  List = 2,
}

export function parseFrontmatterText(fmText: string): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  let section = Section.None;
  let currentKey: string | null = null;
  let currentListKey: string | null = null;
  let currentCite: Record<string, unknown> | null = null;

  for (const line of fmText.split(/\r?\n/)) {
    if (/^\s*$/.test(line) || /^\s*#/.test(line)) {
      if (/^\s*$/.test(line)) currentCite = null;
      continue;
    }
    const kv = line.match(/^(\w[-\w]*):\s*(.*)$/);
    if (kv) {
      const key = kv[1];
      const val = kv[2];
      const flow = val.trim().match(/^\[(.*)\]$/);
      if (key === "cites" || key === "topics" || key === "passMarkers") {
        if (flow) {
          out[key] = flow[1]
            .split(",")
            .map((s) => scalar(s))
            .filter((s) => s !== "");
          section = Section.None;
        } else {
          section = key === "cites" ? Section.Cites : Section.List;
          out[key] = [];
          currentListKey = key;
          currentKey = key;
        }
        continue;
      }
      section = Section.None;
      currentKey = key;
      out[key] = scalar(val);
      continue;
    }
    const listItem = line.match(/^\s*-\s+(.*)$/);
    if (listItem) {
      const rest = listItem[1];
      if (section === Section.Cites) {
        const sub = rest.match(/^file:\s*(.*)$/);
        const subLine = rest.match(/^line:\s*(\d+)\s*$/);
        const subNote = rest.match(/^note:\s*(.*)$/);
        if (sub) {
          currentCite = { file: scalar(sub[1]) };
          (out["cites"] as unknown[]).push(currentCite);
        } else if (subLine) {
          if (currentCite) currentCite.line = Number(subLine[1]);
        } else if (subNote) {
          if (currentCite) currentCite.note = scalar(subNote[1]);
          else (out["cites"] as unknown[]).push({ note: scalar(subNote[1]) });
        }
        continue;
      }
      if (section === Section.List && currentListKey) {
        (out[currentListKey] as unknown[]).push(scalar(rest));
        continue;
      }
      continue;
    }
    const indented = line.match(/^\s+(.*)$/);
    if (indented) {
      const sub = indented[1];
      if (section === Section.List && currentListKey) {
        const v = sub.match(/^-\s+(.*)$/);
        if (v) {
          (out[currentListKey] as unknown[]).push(scalar(v[1]));
          continue;
        }
      }
      if (section === Section.Cites) {
        const f = sub.match(/^file:\s*(.*)$/);
        const ln = sub.match(/^line:\s*(\d+)\s*$/);
        const note = sub.match(/^note:\s*(.*)$/);
        if (f) {
          currentCite = { file: scalar(f[1]) };
          (out["cites"] as unknown[]).push(currentCite);
        } else if (ln && currentCite) {
          currentCite.line = Number(ln[1]);
        } else if (note) {
          if (currentCite) currentCite.note = scalar(note[1]);
          else (out["cites"] as unknown[]).push({ note: scalar(note[1]) });
        }
        continue;
      }
      if (currentKey) {
        const arr = out[currentKey];
        if (Array.isArray(arr)) arr.push(scalar(indented[1]));
        else if (typeof arr === "string") out[currentKey] = arr + " " + stripQuotes(indented[1]);
      }
      continue;
    }
  }
  return out;
}

export function parseFrontmatterRaw(raw: string): ParsedFrontmatter | null {
  const ex = extractFrontmatter(raw);
  if (!ex) return null;
  return { data: parseFrontmatterText(ex.fmText), content: ex.content };
}