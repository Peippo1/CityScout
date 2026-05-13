"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import type { PlanItineraryResponse } from "@/types/itinerary";

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
      payload: itinerary as unknown as Record<string, unknown>
    })
    .select("id")
    .single();

  if (error) {
    console.error("[CityScout] Save itinerary error:", error.message);
    throw new Error("Could not save itinerary.");
  }

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
    console.error("[CityScout] Delete itinerary error:", error.message);
    throw new Error("Could not delete itinerary.");
  }

  revalidatePath("/saved");
}
