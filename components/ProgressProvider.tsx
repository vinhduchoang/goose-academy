"use client";

import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import {
  createEmptyProgress,
  loadProgress,
  saveProgress,
} from "@/lib/progress";
import type { ProgressState } from "@/lib/types";

interface ProgressCtx {
  progress: ProgressState;
  ready: boolean;
  update(fn: (p: ProgressState) => ProgressState): void;
  reset(): void;
}

const Ctx = createContext<ProgressCtx | null>(null);

function makeStorage(): { getItem(k: string): string | null; setItem(k: string, v: string): void } {
  return {
    getItem: (k) => (typeof window === "undefined" ? null : window.localStorage.getItem(k)),
    setItem: (k, v) => {
      if (typeof window !== "undefined") window.localStorage.setItem(k, v);
    },
  };
}

export function ProgressProvider({ children }: { children: React.ReactNode }) {
  const [progress, setProgress] = useState<ProgressState>(() =>
    typeof window === "undefined" ? createEmptyProgress() : loadProgress(makeStorage())
  );
  const [ready, setReady] = useState(false);

  useEffect(() => {
    queueMicrotask(() => {
      setProgress(loadProgress(makeStorage()));
      setReady(true);
    });
  }, []);

  const update = useCallback((fn: (p: ProgressState) => ProgressState) => {
    setProgress((prev) => {
      const next = fn(prev);
      saveProgress(makeStorage(), next);
      return next;
    });
  }, []);

  const reset = useCallback(() => {
    setProgress(createEmptyProgress());
    saveProgress(makeStorage(), createEmptyProgress());
  }, []);

  const value = useMemo(() => ({ progress, ready, update, reset }), [progress, ready, update, reset]);
  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useProgress(): ProgressCtx {
  const ctx = useContext(Ctx);
  if (!ctx) throw new Error("useProgress must be used inside ProgressProvider");
  return ctx;
}