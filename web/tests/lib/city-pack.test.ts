import { describe, it, expect } from "vitest";
import { buildCityPack } from "@/lib/city-pack";
import { CITYSCOUT_CONTENT_VERSION } from "@/types/offline";

describe("buildCityPack", () => {
  it("includes schemaVersion matching CITYSCOUT_CONTENT_VERSION", () => {
    const pack = buildCityPack("Athens");
    expect(pack.schemaVersion).toBe(CITYSCOUT_CONTENT_VERSION);
  });

  it("includes a valid ISO builtAt timestamp", () => {
    const pack = buildCityPack("Athens");
    expect(new Date(pack.builtAt).getTime()).not.toBeNaN();
  });

  it("populates intelligence for Paris (local-intelligence seed entry)", () => {
    const pack = buildCityPack("Paris");
    expect(pack.intelligence).not.toBeNull();
    expect(pack.destination).toBe("Paris");
  });

  it("populates historyMythology for Athens (history-mythology seed entry)", () => {
    const pack = buildCityPack("Athens");
    expect(pack.historyMythology).not.toBeNull();
    expect(pack.destination).toBe("Athens");
  });

  it("returns null contextual fields for unknown destinations", () => {
    const pack = buildCityPack("Atlantis");
    expect(pack.intelligence).toBeNull();
    expect(pack.historyMythology).toBeNull();
  });

  it("includes structuredItinerary when provided", () => {
    const stub = { destination: "Athens", title: "A day", summary: null, stops: [], notes: [] };
    const pack = buildCityPack("Athens", { structuredItinerary: stub });
    expect(pack.structuredItinerary).toBe(stub);
  });

  it("structuredItinerary is null by default", () => {
    const pack = buildCityPack("Athens");
    expect(pack.structuredItinerary).toBeNull();
  });

  it("is fully JSON-serialisable", () => {
    const pack = buildCityPack("Athens");
    expect(() => JSON.stringify(pack)).not.toThrow();
    const round = JSON.parse(JSON.stringify(pack));
    expect(round.destination).toBe("Athens");
  });
});
