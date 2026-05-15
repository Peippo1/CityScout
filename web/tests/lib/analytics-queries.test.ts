import { describe, it, expect } from "vitest";
import { aggregateCounts } from "@/lib/supabase/analytics-queries";

describe("aggregateCounts", () => {
  it("returns empty array for empty input", () => {
    expect(aggregateCounts([])).toEqual([]);
  });

  it("counts occurrences of each value", () => {
    const result = aggregateCounts(["Athens", "Paris", "Athens", "Athens", "Paris"]);
    const athens = result.find((r) => r.label === "Athens");
    const paris = result.find((r) => r.label === "Paris");
    expect(athens?.count).toBe(3);
    expect(paris?.count).toBe(2);
  });

  it("sorts by count descending", () => {
    const result = aggregateCounts(["Rome", "Athens", "Rome", "Rome"]);
    expect(result[0].label).toBe("Rome");
    expect(result[0].count).toBe(3);
    expect(result[1].label).toBe("Athens");
    expect(result[1].count).toBe(1);
  });

  it("handles a single value", () => {
    const result = aggregateCounts(["Tokyo"]);
    expect(result).toHaveLength(1);
    expect(result[0]).toEqual({ label: "Tokyo", count: 1 });
  });

  it("handles all unique values", () => {
    const result = aggregateCounts(["A", "B", "C"]);
    expect(result).toHaveLength(3);
    expect(result.every((r) => r.count === 1)).toBe(true);
  });
});
