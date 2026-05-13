import { historyMythologySeed } from "./seed";
import type { PlaceHistoryMythology } from "@/types/history-mythology";

/**
 * Returns the history & mythology entry for a place, or null when we have
 * no curated content for it. Matching is case-insensitive and covers the
 * canonical name and all configured aliases.
 */
export function getHistoryMythology(place: string): PlaceHistoryMythology | null {
  if (!place.trim()) return null;

  const normalised = place.trim().toLowerCase();

  return (
    historyMythologySeed.find(
      (entry) =>
        entry.place.toLowerCase() === normalised ||
        entry.aliases?.some((alias) => alias.toLowerCase() === normalised)
    ) ?? null
  );
}

/**
 * Collects history & mythology entries for a set of place names, deduplicating
 * by canonical place. Useful for enriching an itinerary that references both
 * a city and specific landmarks within it.
 */
export function getHistoryMythologyForPlaces(
  places: string[]
): PlaceHistoryMythology[] {
  const seen = new Set<string>();
  const results: PlaceHistoryMythology[] = [];

  for (const place of places) {
    const entry = getHistoryMythology(place);
    if (entry && !seen.has(entry.place)) {
      seen.add(entry.place);
      results.push(entry);
    }
  }

  return results;
}

export type { PlaceHistoryMythology };
