import type { SupabaseClient } from "@supabase/supabase-js";
import type { SavedItineraryFull, SavedItineraryRow } from "@/types/saved-itinerary";

/**
 * Fetch lightweight list rows for a user — no large JSON blobs included.
 * Ordered newest-first.
 */
export async function fetchSavedItineraries(
  supabase: SupabaseClient,
  userId: string
): Promise<SavedItineraryRow[]> {
  const { data, error } = await supabase
    .from("saved_itineraries")
    .select("id, destination, title, summary, created_at, updated_at")
    .eq("user_id", userId)
    .order("created_at", { ascending: false });

  if (error) {
    console.error("[CityScout] fetchSavedItineraries error:", error.message);
    return [];
  }

  return data as SavedItineraryRow[];
}

/**
 * Fetch a single itinerary with its full payloads.
 * Returns null if the row does not exist or belongs to a different user
 * (RLS enforces this server-side; the explicit user_id filter is belt-and-suspenders).
 */
export async function fetchSavedItinerary(
  supabase: SupabaseClient,
  id: string,
  userId: string
): Promise<SavedItineraryFull | null> {
  const { data, error } = await supabase
    .from("saved_itineraries")
    .select("id, destination, title, summary, raw_response, structured_itinerary_json, created_at, updated_at")
    .eq("id", id)
    .eq("user_id", userId)
    .single();

  if (error || !data) {
    return null;
  }

  return data as SavedItineraryFull;
}
