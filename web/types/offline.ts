/**
 * Offline-portable type layer for CityScout content.
 *
 * These types describe content that can be pre-packaged into city packs,
 * cached on-device, and consumed without a network connection. They are
 * intentionally serialisation-safe: no functions, no class instances,
 * no circular references, no undefined values.
 *
 * Schema versioning allows clients (web, iOS) to detect when their cached
 * content is stale and needs a refresh. Increment CITYSCOUT_CONTENT_VERSION
 * when any seed file changes in a way that would affect rendered output.
 */

import type { DestinationIntelligence } from "@/types/local-intelligence";
import type { PlaceHistoryMythology } from "@/types/history-mythology";
import type { StructuredItinerary } from "@/types/saved-itinerary";
import type { WalkingNarrative } from "@/types/walking-narrative";

/** Monotonic content version. Bump when any seed data changes. */
export const CITYSCOUT_CONTENT_VERSION = "1.1.0";

/**
 * A portable bundle of all contextual content for a single destination.
 * Designed to be serialised to JSON and cached locally on any client.
 *
 * Extensibility:
 *   - Add walkingNarrative: WalkingNarrative | null when that layer ships.
 *   - Add localGuide: LocalGuide | null for future curated guides.
 *   - builtAt allows clients to show "last updated" and schedule refreshes.
 */
export interface CityPack {
  /** Matches CITYSCOUT_CONTENT_VERSION at pack build time. */
  schemaVersion: string;
  /** ISO 8601 UTC — when this pack was assembled. */
  builtAt: string;
  /** Canonical destination name as stored in the seed data. */
  destination: string;
  intelligence: DestinationIntelligence | null;
  historyMythology: PlaceHistoryMythology | null;
  walkingNarrative: WalkingNarrative | null;
  /** Null until the user has saved an itinerary for this destination. */
  structuredItinerary: StructuredItinerary | null;
}

/** Lightweight manifest entry — does not include content. */
export interface CityPackMeta {
  destination: string;
  schemaVersion: string;
  builtAt: string;
  hasIntelligence: boolean;
  hasHistoryMythology: boolean;
}

export function cityPackMeta(pack: CityPack): CityPackMeta {
  return {
    destination: pack.destination,
    schemaVersion: pack.schemaVersion,
    builtAt: pack.builtAt,
    hasIntelligence: pack.intelligence !== null,
    hasHistoryMythology: pack.historyMythology !== null
  };
}
