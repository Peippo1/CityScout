import type { SupabaseClient } from "@supabase/supabase-js";
import type { JournalEntry } from "@/types/journal";

/**
 * Fetch all journal entries for a saved itinerary, newest first.
 * Returns an empty array on error rather than throwing, so the page
 * degrades gracefully if the table doesn't exist yet.
 */
export async function fetchJournalEntries(
  supabase: SupabaseClient,
  itineraryId: string,
  userId: string
): Promise<JournalEntry[]> {
  const { data, error } = await supabase
    .from("journal_entries")
    .select("id, user_id, itinerary_id, destination, title, body, mood, created_at, updated_at")
    .eq("itinerary_id", itineraryId)
    .eq("user_id", userId)
    .order("created_at", { ascending: false });

  if (error) {
    console.error("[CityScout] fetchJournalEntries error:", error.message);
    return [];
  }

  return (data ?? []) as JournalEntry[];
}
