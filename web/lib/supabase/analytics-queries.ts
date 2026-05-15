import type { SupabaseClient } from "@supabase/supabase-js";

export interface AnalyticsSummary {
  savedItinerariesCount: number;
  journalEntriesCount: number;
  topDestinations: Array<{ label: string; count: number }>;
  topMoods: Array<{ label: string; count: number }>;
  recentSaves: Array<{ destination: string; title: string; created_at: string }>;
}

export async function fetchAnalyticsSummary(
  adminClient: SupabaseClient
): Promise<AnalyticsSummary> {
  const [itinResult, journalResult, destinationResult, moodResult, recentResult] =
    await Promise.all([
      adminClient.from("saved_itineraries").select("id", { count: "exact", head: true }),
      adminClient.from("journal_entries").select("id", { count: "exact", head: true }),
      adminClient.from("saved_itineraries").select("destination").order("destination"),
      adminClient.from("journal_entries").select("mood").not("mood", "is", null),
      adminClient
        .from("saved_itineraries")
        .select("destination, title, created_at")
        .order("created_at", { ascending: false })
        .limit(10)
    ]);

  return {
    savedItinerariesCount: itinResult.count ?? 0,
    journalEntriesCount: journalResult.count ?? 0,
    topDestinations: aggregateCounts(
      (destinationResult.data ?? []).map((r: Record<string, unknown>) => String(r.destination))
    ).slice(0, 10),
    topMoods: aggregateCounts(
      (moodResult.data ?? [])
        .map((r: Record<string, unknown>) => r.mood)
        .filter((m): m is string => typeof m === "string")
    ).slice(0, 8),
    recentSaves: (recentResult.data ?? []) as Array<{
      destination: string;
      title: string;
      created_at: string;
    }>
  };
}

export function aggregateCounts(values: string[]): Array<{ label: string; count: number }> {
  const counts = new Map<string, number>();
  for (const v of values) {
    counts.set(v, (counts.get(v) ?? 0) + 1);
  }
  return Array.from(counts.entries())
    .map(([label, count]) => ({ label, count }))
    .sort((a, b) => b.count - a.count);
}
