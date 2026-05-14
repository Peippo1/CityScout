/**
 * Builds a portable CityPack for a destination.
 *
 * This is a pure synchronous function — no network calls, no side effects.
 * It assembles all available seed content into a single serialisable object
 * that can be:
 *   - Cached to localStorage or SQLite on iOS
 *   - Served as a static JSON file for offline-first deployments
 *   - Versioned and diffed between app releases
 */

import { getIntelligence } from "@/lib/local-intelligence";
import { getHistoryMythology } from "@/lib/history-mythology";
import { CITYSCOUT_CONTENT_VERSION, type CityPack } from "@/types/offline";
import type { StructuredItinerary } from "@/types/saved-itinerary";

export function buildCityPack(
  destination: string,
  options: { structuredItinerary?: StructuredItinerary | null } = {}
): CityPack {
  return {
    schemaVersion: CITYSCOUT_CONTENT_VERSION,
    builtAt: new Date().toISOString(),
    destination,
    intelligence: getIntelligence(destination),
    historyMythology: getHistoryMythology(destination),
    structuredItinerary: options.structuredItinerary ?? null
  };
}
