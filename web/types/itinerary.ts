export interface PlanItineraryRequest {
  destination: string;
  prompt: string;
  preferences: string[];
  saved_places: string[];
}

export type TravelStyleValue = "relaxed" | "food-forward" | "culture" | "neighborhoods" | "night-out";

export interface ItineraryBlock {
  title: string;
  activities: string[];
}

export interface ItineraryStop {
  id: string;
  name: string;
  time_label: string;
  category: string;
  description: string;
  latitude: number | null;
  longitude: number | null;
  matched_poi_id: string | null;
  confidence: number | null;
}

export interface PlanItineraryResponse {
  request_id?: string;
  destination: string;
  generated_at?: string;
  title?: string;
  summary?: string;
  stops?: ItineraryStop[];
  unmatched_stops?: ItineraryStop[];
  morning: ItineraryBlock;
  afternoon: ItineraryBlock;
  evening: ItineraryBlock;
  notes: string[];
}

export interface DraftItineraryStop {
  id: string;
  name: string;
  timeLabel: string;
  category: string;
  description: string;
  latitude: number | null;
  longitude: number | null;
  matchedPoiId: string | null;
  confidence: number | null;
}

export interface DraftItinerary {
  destination: string;
  title: string;
  summary: string;
  generatedAt: string;
  stops: DraftItineraryStop[];
}
