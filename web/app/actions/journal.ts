"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { isJournalMood } from "@/types/journal";
import type { CreateJournalEntryInput, JournalEntry, UpdateJournalEntryInput } from "@/types/journal";

export async function createJournalEntry(
  input: CreateJournalEntryInput
): Promise<{ id: string }> {
  const supabase = await createClient();
  const {
    data: { user }
  } = await supabase.auth.getUser();

  if (!user) throw new Error("Authentication required.");

  const body = input.body.trim();
  if (!body) throw new Error("Journal entry body cannot be empty.");

  const mood = isJournalMood(input.mood) ? input.mood : null;

  const { data, error } = await supabase
    .from("journal_entries")
    .insert({
      user_id: user.id,
      itinerary_id: input.itinerary_id,
      destination: input.destination,
      title: input.title?.trim() || null,
      body,
      mood
    })
    .select("id")
    .single();

  if (error) {
    console.error("[CityScout] Create journal entry error:", error.message);
    throw new Error("Could not save journal entry.");
  }

  revalidatePath(`/saved/${input.itinerary_id}`);
  return { id: data.id };
}

export async function updateJournalEntry(
  id: string,
  itineraryId: string,
  input: UpdateJournalEntryInput
): Promise<void> {
  const supabase = await createClient();
  const {
    data: { user }
  } = await supabase.auth.getUser();

  if (!user) throw new Error("Authentication required.");

  const body = input.body.trim();
  if (!body) throw new Error("Journal entry body cannot be empty.");

  const mood = isJournalMood(input.mood) ? input.mood : null;

  const { error } = await supabase
    .from("journal_entries")
    .update({
      title: input.title?.trim() || null,
      body,
      mood
    })
    .eq("id", id)
    .eq("user_id", user.id); // belt-and-suspenders

  if (error) {
    console.error("[CityScout] Update journal entry error:", error.message);
    throw new Error("Could not update journal entry.");
  }

  revalidatePath(`/saved/${itineraryId}`);
}

export async function deleteJournalEntry(
  id: string,
  itineraryId: string
): Promise<void> {
  const supabase = await createClient();
  const {
    data: { user }
  } = await supabase.auth.getUser();

  if (!user) throw new Error("Authentication required.");

  const { error } = await supabase
    .from("journal_entries")
    .delete()
    .eq("id", id)
    .eq("user_id", user.id);

  if (error) {
    console.error("[CityScout] Delete journal entry error:", error.message);
    throw new Error("Could not delete journal entry.");
  }

  revalidatePath(`/saved/${itineraryId}`);
}
