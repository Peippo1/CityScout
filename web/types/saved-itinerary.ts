import type { PlanItineraryResponse } from "@/types/itinerary";

// -------------------------------------------------------
// Canonical normalised format stored in structured_itinerary_json.
// Decouples the render format from the backend contract so iOS
// and future offline consumers can use this without parsing raw_response.
// Bump STRUCTURED_ITINERARY_VERSION when the shape changes.
// -------------------------------------------------------

export const STRUCTURED_ITINERARY_VERSION = "1.0.0";

export interface StructuredStop {
  id: string;
  name: string;
  timeLabel: string;
  category: string;
  description: string;
  mapped: boolean;
}

export interface StructuredItinerary {
  /** Schema version. Absent on rows saved before versioning was introduced. */
  schemaVersion?: string;
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
