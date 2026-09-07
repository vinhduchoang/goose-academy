export interface Cite {
  file: string;
  line: number;
  note?: string;
}

export interface LessonFrontmatter {
  unit: number;
  unitSlug: string;
  order: number;
  id: string;
  slug: string;
  title: string;
  topics: string[];
  durationMin: number;
  cites: Cite[];
}

export interface TestItem {
  q: string;
  options: string[];
  answer: number;
  topic: string;
  explanation: string[];
}

export interface LessonMeta {
  id: string;
  slug: string;
  unitIndex: number;
  unitSlug: string;
  order: number;
  title: string;
  topics: string[];
  cites: Cite[];
  durationMin: number;
}

export interface UnitMeta {
  slug: string;
  index: number;
  title: string;
  tagline: string;
  lessonCount: number;
}

export interface MiniLab {
  title: string;
  instructions: string;
  verifyScript: string;
  passMarkers: string[];
}

export interface ExamRecord {
  unitSlug: string;
  unitIndex: number;
  title: string;
  questions: TestItem[];
  miniLab: MiniLab;
}

export interface Drill {
  id: string;
  topic: string;
  title: string;
  prompt: string;
  hint: string;
}

export type AttemptScope = "lesson" | "exam";

export interface AttemptItem {
  q: string;
  options: string[];
  answer: number;
  topic: string;
}

export interface Attempt {
  id: string;
  ts: number;
  scope: AttemptScope;
  scopeId: string;
  title: string;
  answers: (number | null)[];
  questions: AttemptItem[];
  score: number;
  correct: number;
  total: number;
  passed: boolean;
  byTopic: Record<string, { correct: number; total: number }>;
}

export interface LessonProgress {
  labVerified: boolean;
  labVerifiedAt: number | null;
  bestScore: number;
  attempts: string[];
}

export interface ExamProgress {
  bestScore: number;
  attempts: string[];
  miniLabPassed: boolean;
  miniLabOutput: string | null;
}

export interface ProgressState {
  version: 1;
  lessons: Record<string, LessonProgress>;
  exams: Record<string, ExamProgress>;
  attempts: Record<string, Attempt>;
}

export interface TopicLessonsIndex {
  [topic: string]: LessonMeta[];
}