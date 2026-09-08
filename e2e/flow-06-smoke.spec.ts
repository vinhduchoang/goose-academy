import { expect, test } from "@playwright/test";

test("TC-E2E-06 guest learner full Unit 0 Lesson 1 journey smoke", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByTestId("unit-cards")).toContainText("Rust for Goose");
  await page.getByTestId("next-up").click();
  await expect(page).toHaveURL(/\/units\/rust-core\/01-toolchain/);

  await expect(page.getByText("workspace", { exact: false }).first()).toBeVisible();
  await expect(page.getByTestId("mind-shift")).toBeVisible();

  await page.getByTestId("tab-lab").click();
  await expect(page.getByTestId("verify-generator")).toBeVisible();
  await page.getByTestId("verify-generator").getByRole("button", { name: "+ Add check" }).click();
  await page.getByTestId("verify-generator").getByRole("button", { name: "Generate" }).click();
  await expect(page.getByTestId("generated-script")).toContainText("VERIFY PASSED");
  await page.getByTestId("lab-verify-toggle").locator("input").check();

  await page.getByTestId("tab-test").click();
  await expect(page.locator("[data-testid^='quiz-option-']").first()).toBeVisible();

  await page.goto("/units/rust-core");
  await expect(page.getByTestId("lesson-list")).toContainText("Toolchain");
  await expect(page.getByTestId("exam-locked")).toBeVisible();

  await page.goto("/drills");
  await expect(page.getByTestId("drill-filter")).toBeVisible();

  await page.goto("/report/at-nonexistent-1");
  await expect(page.getByTestId("report-missing")).toBeVisible();
});