import { expect, test } from "@playwright/test";
import testJson from "../content/units/u0/l01/test.json";

test("TC-E2E-02 remediation loop: weak topic -> suggestions -> retake -> 100 cap", async ({ page }) => {
  const items = testJson as { answer: number; topic: string }[];
  await page.goto("/units/rust-core/01-toolchain");
  await page.getByTestId("tab-test").click();

  for (let i = 0; i < items.length; i++) {
    const wrong = (items[i].answer + 1) % 4;
    await page.getByTestId(`quiz-option-${i}-${wrong}`).click();
  }
  await page.getByTestId("quiz-submit").click();
  await page.getByTestId("quiz-view-report").click();

  await expect(page.getByTestId("score-number")).toHaveText("0");
  await expect(page.getByTestId("remediation-panel")).toBeVisible();
  await expect(page.getByText("Remediation plan")).toBeVisible();
  for (const topic of new Set(items.map((i) => i.topic))) {
    await expect(page.getByTestId(`remediation-topic-${topic}`)).toBeVisible();
  }
  await expect(page.getByTestId("report-retake")).toBeVisible();

  await page.getByTestId("report-retake").click();
  await page.getByTestId("tab-test").click();
  for (let i = 0; i < items.length; i++) {
    await page.getByTestId(`quiz-option-${i}-${items[i].answer}`).click();
  }
  await page.getByTestId("quiz-submit").click();
  await page.getByTestId("quiz-view-report").click();

  await expect(page.getByTestId("score-number")).toHaveText("100");
  await expect(page.getByTestId("remediation-done")).toContainText("capped at 100");
});
