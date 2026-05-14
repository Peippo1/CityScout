import { describe, it, expect } from "vitest";
import { getWalkingNarrative } from "@/lib/walking-narratives";
import { walkingNarrativesSeed } from "@/lib/walking-narratives/seed";

describe("getWalkingNarrative", () => {
  it("returns narrative for an exact match", () => {
    const result = getWalkingNarrative("Athens");
    expect(result).not.toBeNull();
    expect(result?.place).toBe("Athens");
    expect(result?.stops.length).toBeGreaterThan(0);
  });

  it("matches case-insensitively", () => {
    expect(getWalkingNarrative("athens")).not.toBeNull();
    expect(getWalkingNarrative("ACROPOLIS")).not.toBeNull();
  });

  it("matches by alias", () => {
    expect(getWalkingNarrative("Agora of Athens")).not.toBeNull();
    expect(getWalkingNarrative("Athens Agora")).not.toBeNull();
    expect(getWalkingNarrative("Acropolis of Athens")).not.toBeNull();
  });

  it("returns null for unknown place", () => {
    expect(getWalkingNarrative("Paris")).toBeNull();
    expect(getWalkingNarrative("Atlantis")).toBeNull();
  });

  it("returns null for empty or whitespace string", () => {
    expect(getWalkingNarrative("")).toBeNull();
    expect(getWalkingNarrative("   ")).toBeNull();
  });
});

describe("seed integrity", () => {
  it("every narrative has a title, intro, and at least 3 stops", () => {
    for (const narrative of walkingNarrativesSeed) {
      expect(narrative.title.trim(), `${narrative.place} missing title`).not.toBe("");
      expect(narrative.intro.trim(), `${narrative.place} missing intro`).not.toBe("");
      expect(narrative.stops.length, `${narrative.place} has too few stops`).toBeGreaterThanOrEqual(3);
    }
  });

  it("every stop has a non-empty id, name, and passage", () => {
    const validTypes = new Set([
      "approach", "landmark", "viewpoint", "history",
      "mythology", "architecture", "transition"
    ]);
    for (const narrative of walkingNarrativesSeed) {
      for (const stop of narrative.stops) {
        expect(stop.id.trim(), `Empty id in ${narrative.place}`).not.toBe("");
        expect(stop.name.trim(), `Empty name in ${narrative.place}`).not.toBe("");
        expect(stop.passage.trim(), `Empty passage in ${narrative.place}`).not.toBe("");
        expect(validTypes.has(stop.type), `Invalid type "${stop.type}" in ${narrative.place}`).toBe(true);
      }
    }
  });

  it("stop ids are unique within each narrative", () => {
    for (const narrative of walkingNarrativesSeed) {
      const ids = narrative.stops.map((s) => s.id);
      const unique = new Set(ids);
      expect(unique.size, `Duplicate stop ids in ${narrative.place}`).toBe(ids.length);
    }
  });
});
