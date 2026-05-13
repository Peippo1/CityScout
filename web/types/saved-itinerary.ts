import type { PlanItineraryResponse } from "@/types/itinerary";

// -------------------------------------------------------
// Normalised display format stored in structured_itinerary_json.
// Decouples the render format from the backend contract so iOS
// and future offline consumers can use this without parsing raw_response.
// -------------------------------------------------------

export interface StructuredStop {
  id: string;
  name: string;
  timeLabel: string;
  category: string;
  description: string;
  mapped: boolean;
}

export interface StructuredItinerary {
  destination: string;
  title: string;
  summary: string | null;
  stops: StructuredStop[];
  notes: string[];
}

// -------------------------------------------------------
// Database row shapes
// -------------------------------------------------------

/** Lightweight row returned by list queries (no large JSON blobs). */
export interface SavedItineraryRow {
  id: string;
  destination: string;
  title: string;
  summary: string | null;
  created_at: string;
  updated_at: string;
}

/** Full row including payloads, returned when reopening a saved itinerary. */
export interface SavedItineraryFull extends SavedItineraryRow {
  raw_response: PlanItineraryResponse;
  structured_itinerary_json: StructuredItinerary | null;
}
