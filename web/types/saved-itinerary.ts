import type { PlanItineraryResponse } from "@/types/itinerary";

/** Row returned by the list query (no payload — payload is large). */
export interface SavedItineraryRow {
  id: string;
  destination: string;
  title: string;
  summary: string | null;
  created_at: string;
}

/** Full row including payload, used when reopening a saved itinerary. */
export interface SavedItineraryFull extends SavedItineraryRow {
  payload: PlanItineraryResponse;
}
