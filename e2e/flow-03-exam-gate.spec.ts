import { expect, test } from "@playwright/test";
import u0Exam from "../content/exams/u0.json";

const LESSON_IDS = Array.from({ length: 15 }, (_, i) => `u0-l${String(i + 1).padStart(2, "0")}`);

const COMPLETE_STATE = {
  version: 1,
  lessons: Object.fromEntries(
    LESSON_IDS.map((id) => [id, { labVerified: true, labVerifiedAt: 1, bestScore: 100, attempts: [] }])
  ),
  exams: {},
  attempts: {},
};

test("TC-E2E-03a exam gating: locked until all unit lessons are complete", async ({ page }) => {
  await page.goto("/exam/rust-core");
  await expect(page.getByTestId("exam-locked-page")).toBeVisible();
  await expect(page.getByText(/locked/i)).toBeVisible();
});

test("TC-E2E-03b exam unlock + mini-lab auto-grading verdict", async ({ page }) => {
  await page.addInitScript((state) => {
    window.localStorage.setItem("goose-academy-progress-v1", JSON.stringify(state));
  }, COMPLETE_STATE);

  await page.goto("/units/rust-core");
  await expect(page.getByTestId("exam-link")).toBeVisible();
  await page.getByTestId("exam-link").click();
  await expect(page).toHaveURL(/\/exam\/rust-core/);

  await expect(page.getByTestId("quiz")).toBeVisible();

  const questionCount = u0Exam.questions.length;
  for (let i = 0; i < questionCount; i++) {
    await page.getByTestId(`quiz-option-${i}-${u0Exam.questions[i].answer}`).click();
  }
  await page.getByTestId("quiz-submit").click();
  await page.getByTestId("quiz-view-report").click();
  await expect(page.getByTestId("score-number")).toHaveText("100");
});

test("TC-E2E-03c mini-lab verdict: PASS with all markers, FAIL when missing", async ({ page }) => {
  await page.addInitScript((state) => {
    window.localStorage.setItem("goose-academy-progress-v1", JSON.stringify(state));
  }, COMPLETE_STATE);

  await page.goto("/exam/rust-core");

  const markers = u0Exam.miniLab.passMarkers;
  await page.getByTestId("minilab-output").fill("whatever");
  await page.getByTestId("minilab-grade").click();
  await expect(page.getByTestId("minilab-verdict")).toContainText("FAIL");

  await page.getByTestId("minilab-output").fill(markers.map((m) => `- ${m}`).join("\n"));
  await page.getByTestId("minilab-grade").click();
  await expect(page.getByTestId("minilab-verdict")).toContainText("PASS");
});
