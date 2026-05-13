import { intelligenceSeed } from "./seed";
import type { DestinationIntelligence, IntelligenceTip } from "@/types/local-intelligence";

/**
 * Returns tips for a destination, or null if we have no data for it.
 * Matching is case-insensitive and considers the canonical name and aliases.
 */
export function getIntelligence(destination: string): DestinationIntelligence | null {
  if (!destination.trim()) return null;

  const normalised = destination.trim().toLowerCase();

  return (
    intelligenceSeed.find(
      (entry) =>
        entry.destination.toLowerCase() === normalised ||
        entry.aliases?.some((alias) => alias.toLowerCase() === normalised)
    ) ?? null
  );
}

export type { DestinationIntelligence, IntelligenceTip };
