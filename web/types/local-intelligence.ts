export type IntelligenceCategory =
  | "cultural"
  | "transport"
  | "practical"
  | "food";

export interface IntelligenceTip {
  category: IntelligenceCategory;
  tip: string;
}

export interface DestinationIntelligence {
  /** Canonical destination name used for matching. */
  destination: string;
  /** Additional names this destination may appear as (case-insensitive). */
  aliases?: string[];
  tips: IntelligenceTip[];
}
