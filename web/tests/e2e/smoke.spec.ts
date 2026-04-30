import { expect, test } from "@playwright/test";

test("homepage smoke check", async ({ page }) => {
  await page.goto("/");

  await expect(page.getByRole("heading", { name: /Plan city days with the same care/i })).toBeVisible();
  await expect(page.getByRole("link", { name: /Start planning/i })).toBeVisible();
});
