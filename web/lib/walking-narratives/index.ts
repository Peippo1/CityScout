import { walkingNarrativesSeed } from "./seed";
import type { WalkingNarrative } from "@/types/walking-narrative";

/**
 * Returns the walking narrative for a place, or null if none exists.
 * Matching is case-insensitive and considers aliases.
 */
export function getWalkingNarrative(place: string): WalkingNarrative | null {
  if (!place.trim()) return null;

  const normalised = place.trim().toLowerCase();

  return (
    walkingNarrativesSeed.find(
      (entry) =>
        entry.place.toLowerCase() === normalised ||
        entry.aliases?.some((alias) => alias.toLowerCase() === normalised)
    ) ?? null
  );
}

export type { WalkingNarrative };
