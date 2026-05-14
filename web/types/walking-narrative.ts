/**
 * Walking Narrative types.
 *
 * A walking narrative is an ordered sequence of stops, each with a short
 * atmospheric passage. Designed for future audio guide integration and
 * offline city packs — all fields are serialisation-safe.
 *
 * Extensibility:
 *   Add audioUrl, imageUrl, or gpsCoordinates when those features are ready.
 *   Add languageCode for multilingual support.
 */

export type NarrativeStopType =
  | "approach"      // arriving at the area
  | "landmark"      // a named building or structure
  | "viewpoint"     // a place to pause and observe
  | "history"       // a historical layer
  | "mythology"     // a mythological or legendary moment
  | "architecture"  // an architectural observation
  | "transition";   // moving between locations

export interface NarrativeStop {
  id: string;
  name: string;
  type: NarrativeStopType;
  /** Two to four atmospheric sentences. Concise; not a lecture. */
  passage: string;
  /** Optional note about what to look for. */
  lookFor?: string;
}

export interface WalkingNarrative {
  /** Canonical place name. Used for matching. */
  place: string;
  aliases?: string[];
  /** Short title shown in the UI. */
  title: string;
  /** One sentence setting the scene. */
  intro: string;
  /** Estimated duration in minutes. */
  durationMinutes: number;
  stops: NarrativeStop[];
}
