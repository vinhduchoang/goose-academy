import { expect, test } from "@playwright/test";
import testJson from "../content/units/u0/l01/test.json";

test("TC-E2E-01 lesson: theory -> lab view -> test -> score renders", async ({ page }) => {
  await page.goto("/units/rust-core/01-toolchain");

  await expect(page.getByRole("heading", { name: /Toolchain: rustup/ }).first()).toBeVisible();
  await expect(page.getByTestId("founder-lens")).toBeVisible();

  await page.getByTestId("tab-lab").click();
  await expect(page.getByTestId("lab-runner")).toBeVisible();
  await await expect(page.getByTestId("lab-runner").getByText("VERIFY PASSED").first()).toBeVisible();
  await page.getByTestId("lab-verify-toggle").locator("input").check();

  await page.getByTestId("tab-test").click();
  await expect(page.getByTestId("quiz")).toBeVisible();
  await expect(page.getByTestId("quiz-submit")).toBeDisabled();

  const items = testJson as { answer: number }[];
  for (let i = 0; i < items.length; i++) {
    await page.getByTestId(`quiz-option-${i}-${items[i].answer}`).click();
  }
  await page.getByTestId("quiz-submit").click();
  await page.getByTestId("quiz-view-report").click();

  await expect(page).toHaveURL(/\/report\//);
  await expect(page.getByTestId("score-number")).toHaveText("100");
  await expect(page.getByTestId("score-breakdown")).toBeVisible();
  await expect(page.getByTestId("remediation-done")).toBeVisible();
});
