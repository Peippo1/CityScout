export const JOURNAL_MOODS = [
  "reflective",
  "adventurous",
  "relaxed",
  "energetic",
  "romantic",
  "overwhelmed"
] as const;

export type JournalMood = (typeof JOURNAL_MOODS)[number];

export function isJournalMood(value: unknown): value is JournalMood {
  return typeof value === "string" && (JOURNAL_MOODS as readonly string[]).includes(value);
}

// -------------------------------------------------------
// Database row shape
// -------------------------------------------------------

export interface JournalEntry {
  id: string;
  user_id: string;
  itinerary_id: string;
  destination: string;
  title: string | null;
  body: string;
  mood: JournalMood | null;
  created_at: string;
  updated_at: string;
}

// -------------------------------------------------------
// Mutation input shapes
// -------------------------------------------------------

export interface CreateJournalEntryInput {
  itinerary_id: string;
  destination: string;
  title: string | null;
  body: string;
  mood: JournalMood | null;
}

export interface UpdateJournalEntryInput {
  title: string | null;
  body: string;
  mood: JournalMood | null;
}
