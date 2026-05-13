import { describe, it, expect } from "vitest";
import { getHistoryMythology, getHistoryMythologyForPlaces } from "@/lib/history-mythology";
import { historyMythologySeed } from "@/lib/history-mythology/seed";

describe("getHistoryMythology", () => {
  it("returns entry for an exact match", () => {
    const result = getHistoryMythology("Athens");
    expect(result).not.toBeNull();
    expect(result?.place).toBe("Athens");
    expect(result?.stories.length).toBeGreaterThan(0);
  });

  it("matches case-insensitively", () => {
    expect(getHistoryMythology("athens")).not.toBeNull();
    expect(getHistoryMythology("MARATHON")).not.toBeNull();
    expect(getHistoryMythology("Paros")).not.toBeNull();
  });

  it("matches by alias", () => {
    expect(getHistoryMythology("Acropolis of Athens")).not.toBeNull();
    expect(getHistoryMythology("Athens Agora")).not.toBeNull();
    expect(getHistoryMythology("Paros Island")).not.toBeNull();
  });

  it("returns null for unknown place", () => {
    expect(getHistoryMythology("Atlantis")).toBeNull();
    expect(getHistoryMythology("London")).toBeNull();
  });

  it("returns null for empty or whitespace string", () => {
    expect(getHistoryMythology("")).toBeNull();
    expect(getHistoryMythology("   ")).toBeNull();
  });

  it("returns all 6 seeded places", () => {
    const places = ["Athens", "Acropolis", "Ancient Agora", "Paros", "Naxos", "Marathon"];
    for (const place of places) {
      expect(getHistoryMythology(place), `No entry for ${place}`).not.toBeNull();
    }
  });
});

describe("getHistoryMythologyForPlaces", () => {
  it("returns entries for multiple known places", () => {
    const results = getHistoryMythologyForPlaces(["Athens", "Marathon"]);
    expect(results).toHaveLength(2);
  });

  it("deduplicates when the same place appears twice", () => {
    const results = getHistoryMythologyForPlaces(["Athens", "athens", "Athens"]);
    expect(results).toHaveLength(1);
  });

  it("silently skips unknown places", () => {
    const results = getHistoryMythologyForPlaces(["Athens", "Nowhere", "Marathon"]);
    expect(results).toHaveLength(2);
    expect(results.map((r) => r.place)).toEqual(["Athens", "Marathon"]);
  });

  it("returns empty array for all unknown places", () => {
    expect(getHistoryMythologyForPlaces(["Atlantis", "Narnia"])).toEqual([]);
  });

  it("returns empty array for empty input", () => {
    expect(getHistoryMythologyForPlaces([])).toEqual([]);
  });
});

describe("seed integrity", () => {
  it("every entry has at least one story", () => {
    for (const entry of historyMythologySeed) {
      expect(entry.stories.length, `${entry.place} has no stories`).toBeGreaterThan(0);
    }
  });

  it("every story has non-empty headline and body", () => {
    const validCategories = new Set(["mythology", "history", "landmark", "culture"]);
    for (const entry of historyMythologySeed) {
      for (const story of entry.stories) {
        expect(story.headline.trim(), `Empty headline in ${entry.place}`).not.toBe("");
        expect(story.body.trim(), `Empty body in ${entry.place}`).not.toBe("");
        expect(
          validCategories.has(story.category),
          `Invalid category "${story.category}" in ${entry.place}`
        ).toBe(true);
      }
    }
  });

  it("every recommended reading item has title and author", () => {
    for (const entry of historyMythologySeed) {
      for (const item of entry.reading ?? []) {
        expect(item.title.trim(), `Empty title in ${entry.place}`).not.toBe("");
        expect(item.author.trim(), `Empty author in ${entry.place}`).not.toBe("");
      }
    }
  });
});
