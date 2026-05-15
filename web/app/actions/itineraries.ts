"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { log } from "@/lib/logger";
import type { PlanItineraryResponse, ItineraryStop } from "@/types/itinerary";
import { STRUCTURED_ITINERARY_VERSION } from "@/types/saved-itinerary";
import type { StructuredItinerary, StructuredStop } from "@/types/saved-itinerary";

export interface SaveItineraryResult {
  id: string;
}

export async function saveItinerary(
  itinerary: PlanItineraryResponse
): Promise<SaveItineraryResult> {
  const supabase = await createClient();
  const {
    data: { user }
  } = await supabase.auth.getUser();

  if (!user) {
    throw new Error("Authentication required.");
  }

  const { data, error } = await supabase
    .from("saved_itineraries")
    .insert({
      user_id: user.id,
      destination: itinerary.destination,
      title: itinerary.title ?? itinerary.destination,
      summary: itinerary.summary ?? null,
      raw_response: itinerary as unknown as Record<string, unknown>,
      structured_itinerary_json: buildStructuredItinerary(itinerary)
    })
    .select("id")
    .single();

  if (error) {
    log({ level: "error", route: "saveItinerary", event: "save_failed", error: error.message });
    throw new Error("Could not save itinerary.");
  }

  log({
    level: "info",
    route: "saveItinerary",
    event: "save_complete",
    destination: itinerary.destination
  });
  revalidatePath("/saved");
  return { id: data.id };
}

export async function deleteItinerary(id: string): Promise<void> {
  const supabase = await createClient();
  const {
    data: { user }
  } = await supabase.auth.getUser();

  if (!user) {
    throw new Error("Authentication required.");
  }

  const { error } = await supabase
    .from("saved_itineraries")
    .delete()
    .eq("id", id)
    .eq("user_id", user.id); // belt-and-suspenders alongside RLS

  if (error) {
    log({ level: "error", route: "deleteItinerary", event: "delete_failed", error: error.message });
    throw new Error("Could not delete itinerary.");
  }

  log({ level: "info", route: "deleteItinerary", event: "delete_complete" });
  revalidatePath("/saved");
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

function buildStructuredItinerary(
  itinerary: PlanItineraryResponse
): StructuredItinerary {
  const stops: StructuredStop[] =
    itinerary.stops && itinerary.stops.length > 0
      ? itinerary.stops.map(toStructuredStop)
      : legacyBlocksToStructuredStops(itinerary);

  return {
    schemaVersion: STRUCTURED_ITINERARY_VERSION,
    destination: itinerary.destination,
    title: itinerary.title ?? itinerary.destination,
    summary: itinerary.summary ?? null,
    stops,
    notes: itinerary.notes ?? []
  };
}

function toStructuredStop(stop: ItineraryStop): StructuredStop {
  return {
    id: stop.id,
    name: stop.name,
    timeLabel: stop.time_label,
    category: stop.category,
    description: stop.description,
    mapped: stop.latitude !== null && stop.longitude !== null
  };
}

function legacyBlocksToStructuredStops(
  itinerary: PlanItineraryResponse
): StructuredStop[] {
  const blocks: Array<[string, string[]]> = [
    ["Morning", itinerary.morning?.activities ?? []],
    ["Afternoon", itinerary.afternoon?.activities ?? []],
    ["Evening", itinerary.evening?.activities ?? []]
  ];

  return blocks.flatMap(([timeLabel, activities], blockIndex) =>
    activities.map((activity, activityIndex) => ({
      id: `${timeLabel.toLowerCase()}-${blockIndex}-${activityIndex}`,
      name: activity,
      timeLabel,
      category: "planned stop",
      description: activity,
      mapped: false
    }))
  );
}
