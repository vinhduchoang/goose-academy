export interface CheckSpec {
  name: string;
  kind: "file-exists" | "content-match" | "notes-exists" | "cargo-metadata";
  detail: string;
  path?: string;
  pattern?: string;
}

export function generateVerifyScript(
  lessonId: string,
  title: string,
  checks: CheckSpec[]
): string {
  const lines: string[] = [];
  lines.push(`# Goose Contributor Academy - Lab check: ${lessonId} ${title}`);
  lines.push(`# Run from any directory. Validates your lab work.`);
  lines.push(`param(`);
  lines.push(`    [string]$GooseRepo = $env:GOOSE_REPO`);
  lines.push(`)`);
  lines.push(``);
  lines.push(`$ErrorActionPreference = "Stop"`);
  lines.push(`$fails = 0`);
  lines.push(`$passes = 0`);
  lines.push(``);
  lines.push(`if (-not $GooseRepo) {`);
  lines.push(`    $GooseRepo = "C:\\Users\\admin\\projects\\goose"`);
  lines.push(`    Write-Host "[INFO]  GOOSE_REPO not set; trying default: $GooseRepo"`);
  lines.push(`}`);
  lines.push(``);
  lines.push(`function Check {`);
  lines.push(`    param([string]$Name, [bool]$Ok, [string]$Detail)`);
  lines.push(`    if ($Ok) {`);
  lines.push(`        Write-Host "[PASS]  $Name"`);
  lines.push(`        $script:passes++`);
  lines.push(`    } else {`);
  lines.push(`        Write-Host "[FAIL]  $Name - $Detail"`);
  lines.push(`        $script:fails++`);
  lines.push(`    }`);
  lines.push(`}`);
  lines.push(``);
  checks.forEach((c) => {
    const esc = (s: string) => s.replace(/\\/g, "\\\\").replace(/"/g, '`"');
    lines.push(`# ${c.name}`);
    switch (c.kind) {
      case "file-exists":
        lines.push(`$ok = Test-Path (Join-Path $GooseRepo "${esc(c.path ?? "")}")`);
        lines.push(`Check "${esc(c.name)}" $ok "${esc(c.detail)}"`);
        break;
      case "content-match":
        lines.push(`$ok = $false`);
        lines.push(`$f = Get-Content (Join-Path $GooseRepo "${esc(c.path ?? "")}") -Raw -ErrorAction SilentlyContinue`);
        lines.push(`if ($f) { $ok = $f -match '${esc(c.pattern ?? "")}' }`);
        lines.push(`Check "${esc(c.name)}" $ok "expected match in ${esc(c.path ?? "")}"`);
        break;
      case "notes-exists":
        lines.push(`$ok = Test-Path (Join-Path (Get-Location) "${esc(c.path ?? "")}")`);
        lines.push(`Check "${esc(c.name)}" $ok "${esc(c.detail)}"`);
        break;
      case "cargo-metadata":
        lines.push(`$ok = $false`);
        lines.push(`Push-Location $GooseRepo`);
        lines.push(`try {`);
        lines.push(`    $names = @(cargo metadata --no-deps --format-version 1 2>$null | ConvertFrom-Json).packages | ForEach-Object { $_.name }`);
        lines.push(`    $ok = ($names -contains "${esc(c.pattern ?? "")}")`);
        lines.push(`} catch { $ok = $false }`);
        lines.push(`Pop-Location`);
        lines.push(`Check "${esc(c.name)}" $ok "${esc(c.detail)}"`);
        break;
    }
    lines.push(``);
  });
  lines.push(`Write-Host ""`);
  lines.push(`if ($fails -eq 0) {`);
  lines.push(`    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"`);
  lines.push(`    exit 0`);
  lines.push(`} else {`);
  lines.push(`    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"`);
  lines.push(`    exit 1`);
  lines.push(`}`);
  return lines.join("\r\n") + "\r\n";
}

export interface Verdict {
  passed: boolean;
  found: string[];
  missing: string[];
}

export function parseVerifyVerdict(output: string, passMarkers: string[]): Verdict {
  const found: string[] = [];
  const missing: string[] = [];
  for (const marker of passMarkers) {
    if (output.includes(marker)) found.push(marker);
    else missing.push(marker);
  }
  return { passed: missing.length === 0, found, missing };
}