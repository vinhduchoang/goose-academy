import { expect, test } from "@playwright/test";
import testJson from "../content/units/u0/l01/test.json";

test("TC-E2E-04 dashboard progress persists across reload", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByTestId("next-up")).toContainText("Toolchain");

  await page.goto("/units/rust-core/01-toolchain");
  await page.getByTestId("tab-lab").click();
  await page.getByTestId("lab-verify-toggle").locator("input").check();
  await page.getByTestId("tab-test").click();
  const items = testJson as { answer: number }[];
  for (let i = 0; i < items.length; i++) {
    await page.getByTestId(`quiz-option-${i}-${items[i].answer}`).click();
  }
  await page.getByTestId("quiz-submit").click();

  await page.goto("/");
  await expect(page.getByTestId("unit-cards")).toContainText("1/15 lessons complete");
  await expect(page.getByTestId("next-up")).toContainText("Data types");

  await page.reload();
  await expect(page.getByTestId("unit-cards")).toContainText("1/15 lessons complete");
  await expect(page.getByTestId("progress-ring").first()).toHaveAttribute("aria-label", "2%");
});