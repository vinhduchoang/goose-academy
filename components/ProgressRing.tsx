import type { CSSProperties } from "react";

export function ProgressRing({
  pct,
  size = 64,
  stroke = 6,
  label,
}: {
  pct: number;
  size?: number;
  stroke?: number;
  label?: string;
}) {
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const clamped = Math.max(0, Math.min(100, pct));
  const style: CSSProperties = {
    strokeDasharray: `${(clamped / 100) * c} ${c}`,
  };
  return (
    <div
      className="relative inline-flex items-center justify-center"
      data-testid="progress-ring"
      aria-label={`${clamped}%`}
    >
      <svg width={size} height={size} className="-rotate-90">
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          fill="none"
          strokeWidth={stroke}
          className="stroke-zinc-200 dark:stroke-zinc-700"
        />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          fill="none"
          strokeWidth={stroke}
          strokeLinecap="round"
          className="stroke-sky-500 transition-all duration-500"
          style={style}
        />
      </svg>
      <span className="absolute text-xs font-semibold text-zinc-700 dark:text-zinc-200">
        {label ?? `${clamped}%`}
      </span>
    </div>
  );
}