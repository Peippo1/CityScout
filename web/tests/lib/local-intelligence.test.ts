import { describe, it, expect } from "vitest";
import { getIntelligence } from "@/lib/local-intelligence";
import { intelligenceSeed } from "@/lib/local-intelligence/seed";

describe("getIntelligence", () => {
  it("returns data for an exact match", () => {
    const result = getIntelligence("Paris");
    expect(result).not.toBeNull();
    expect(result?.destination).toBe("Paris");
    expect(result?.tips.length).toBeGreaterThan(0);
  });

  it("matches case-insensitively", () => {
    expect(getIntelligence("paris")).not.toBeNull();
    expect(getIntelligence("PARIS")).not.toBeNull();
    expect(getIntelligence("Tokyo")).not.toBeNull();
  });

  it("matches by alias", () => {
    expect(getIntelligence("nyc")).not.toBeNull();
    expect(getIntelligence("NYC")).not.toBeNull();
    expect(getIntelligence("New York City")).not.toBeNull();
  });

  it("returns null for unknown destination", () => {
    expect(getIntelligence("Atlantis")).toBeNull();
    expect(getIntelligence("Nowhere")).toBeNull();
  });

  it("returns null for empty string", () => {
    expect(getIntelligence("")).toBeNull();
    expect(getIntelligence("   ")).toBeNull();
  });

  it("all seed entries have at least one tip", () => {
    for (const entry of intelligenceSeed) {
      expect(entry.tips.length, `${entry.destination} has no tips`).toBeGreaterThan(0);
    }
  });

  it("every tip has a non-empty tip string and valid category", () => {
    const validCategories = new Set(["cultural", "transport", "practical", "food"]);
    for (const entry of intelligenceSeed) {
      for (const tip of entry.tips) {
        expect(tip.tip.trim(), `Empty tip in ${entry.destination}`).not.toBe("");
        expect(
          validCategories.has(tip.category),
          `Invalid category "${tip.category}" in ${entry.destination}`
        ).toBe(true);
      }
    }
  });
});
