export type StoryCategory =
  | "mythology"    // gods, heroes, origin myths
  | "history"      // events, periods, rulers
  | "landmark"     // specific site narratives
  | "culture";     // customs, art, philosophy

export interface RecommendedReading {
  title: string;
  author: string;
  note?: string;
}

export interface HistoryStory {
  category: StoryCategory;
  headline: string;
  body: string;
  /** If set, this story is tied to a specific named place inside the city. */
  landmark?: string;
}

export interface PlaceHistoryMythology {
  /**
   * Canonical name used for matching. Can be a city or a landmark.
   * Matching is case-insensitive.
   */
  place: string;
  /** Alternate names and spellings this place may appear as. */
  aliases?: string[];
  stories: HistoryStory[];
  reading?: RecommendedReading[];
}
