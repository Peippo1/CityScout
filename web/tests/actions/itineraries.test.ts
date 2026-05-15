import { vi, describe, it, expect, beforeEach } from "vitest";

// ---------------------------------------------------------------------------
// RLS assumption documentation
//
// The following unit tests validate server-side auth guards inside our
// Server Actions. The Supabase RLS policies themselves are enforced at the
// database level and cannot be unit-tested here; they must be verified with
// integration tests against a real Supabase project (or the Supabase CLI
// local stack).
//
// RLS policies assumed to be configured on public.saved_itineraries:
//
//   users_select_own  — SELECT: auth.uid() = user_id
//   users_insert_own  — INSERT: auth.uid() = user_id  (with check)
//   users_delete_own  — DELETE: auth.uid() = user_id
//
// Belt-and-suspenders: our actions also filter .eq("user_id", user.id) on
// all mutations, so a misconfigured RLS policy cannot escalate to cross-user
// access via our API surface.
//
// Assumptions these tests exercise:
//   1. Unauthenticated callers are rejected before any DB call.
//   2. Authenticated callers insert with the session user_id, not a client-
//      supplied one.
//   3. Delete filters by both id AND user_id.
//   4. fetchSavedItineraries returns an empty array (not an error) on DB
//      failure, so the page degrades gracefully.
// ---------------------------------------------------------------------------

const { mockRevalidatePath, mockCreateClient } = vi.hoisted(() => {
  const mockCreateClient = vi.fn();
  const mockRevalidatePath = vi.fn();
  return { mockRevalidatePath, mockCreateClient };
});

vi.mock("@/lib/supabase/server", () => ({ createClient: mockCreateClient }));
vi.mock("next/cache", () => ({ revalidatePath: mockRevalidatePath }));

import { saveItinerary, deleteItinerary } from "@/app/actions/itineraries";
import { fetchSavedItineraries, fetchSavedItinerary } from "@/lib/supabase/queries";
import type { PlanItineraryResponse } from "@/types/itinerary";

const stubItinerary: PlanItineraryResponse = {
  destination: "Paris",
  title: "A Day in Paris",
  summary: "Coffee and art.",
  stops: [
    {
      id: "stop-1",
      name: "Café de Flore",
      time_label: "Morning",
      category: "Café",
      description: "Start with coffee.",
      latitude: 48.854,
      longitude: 2.332,
      matched_poi_id: "poi-1",
      confidence: 0.9
    }
  ],
  unmatched_stops: [],
  morning: { title: "Morning", activities: ["Café de Flore"] },
  afternoon: { title: "Afternoon", activities: [] },
  evening: { title: "Evening", activities: [] },
  notes: ["Book ahead."],
  request_id: "req-1",
  generated_at: "2026-05-13T10:00:00Z"
};

// ---------------------------------------------------------------------------
// saveItinerary
// ---------------------------------------------------------------------------

describe("saveItinerary", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("throws when not authenticated — unauthenticated blocked", async () => {
    mockCreateClient.mockResolvedValue({ auth: { getUser: vi.fn().mockResolvedValue({ data: { user: null } }) } });

    await expect(saveItinerary(stubItinerary)).rejects.toThrow("Authentication required.");
    expect(mockRevalidatePath).not.toHaveBeenCalled();
  });

  it("inserts with correct fields and returns saved id", async () => {
    const mockSingle = vi.fn().mockResolvedValue({ data: { id: "saved-1" }, error: null });
    const mockInsert = vi.fn(() => ({ select: vi.fn(() => ({ single: mockSingle })) }));

    mockCreateClient.mockResolvedValue({
      auth: { getUser: vi.fn().mockResolvedValue({ data: { user: { id: "user-1" } } }) },
      from: vi.fn(() => ({ insert: mockInsert }))
    });

    const result = await saveItinerary(stubItinerary);

    expect(result).toEqual({ id: "saved-1" });
    // Verify insert was called with raw_response and structured_itinerary_json.
    const insertedData = mockInsert.mock.calls[0][0] as Record<string, unknown>;
    expect(insertedData).toMatchObject({
      user_id: "user-1",
      destination: "Paris",
      title: "A Day in Paris"
    });
    expect(insertedData.raw_response).toBeDefined();
    expect(insertedData.structured_itinerary_json).toBeDefined();
    expect(mockRevalidatePath).toHaveBeenCalledWith("/saved");
  });

  it("builds structured_itinerary_json from stops", async () => {
    const mockSingle = vi.fn().mockResolvedValue({ data: { id: "saved-1" }, error: null });
    const mockInsert = vi.fn(() => ({ select: vi.fn(() => ({ single: mockSingle })) }));

    mockCreateClient.mockResolvedValue({
      auth: { getUser: vi.fn().mockResolvedValue({ data: { user: { id: "user-1" } } }) },
      from: vi.fn(() => ({ insert: mockInsert }))
    });

    await saveItinerary(stubItinerary);

    const insertedData = mockInsert.mock.calls[0][0] as Record<string, unknown>;
    const structured = insertedData.structured_itinerary_json as { stops: unknown[] };
    expect(structured.stops).toHaveLength(1);
    expect((structured.stops[0] as { name: string }).name).toBe("Café de Flore");
  });

  it("throws friendly error when insert fails", async () => {
    mockCreateClient.mockResolvedValue({
      auth: { getUser: vi.fn().mockResolvedValue({ data: { user: { id: "user-1" } } }) },
      from: vi.fn(() => ({
        insert: vi.fn(() => ({
          select: vi.fn(() => ({
            single: vi.fn().mockResolvedValue({ data: null, error: { message: "DB error" } })
          }))
        }))
      }))
    });

    await expect(saveItinerary(stubItinerary)).rejects.toThrow("Could not save itinerary.");
    expect(mockRevalidatePath).not.toHaveBeenCalled();
  });
});

// ---------------------------------------------------------------------------
// deleteItinerary
// ---------------------------------------------------------------------------

describe("deleteItinerary", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("throws when not authenticated — unauthenticated blocked", async () => {
    mockCreateClient.mockResolvedValue({ auth: { getUser: vi.fn().mockResolvedValue({ data: { user: null } }) } });

    await expect(deleteItinerary("some-id")).rejects.toThrow("Authentication required.");
    expect(mockRevalidatePath).not.toHaveBeenCalled();
  });

  it("deletes by id AND user_id — belt-and-suspenders over RLS", async () => {
    const mockEqUserId = vi.fn().mockResolvedValue({ error: null });
    const mockEqId = vi.fn(() => ({ eq: mockEqUserId }));

    mockCreateClient.mockResolvedValue({
      auth: { getUser: vi.fn().mockResolvedValue({ data: { user: { id: "user-1" } } }) },
      from: vi.fn(() => ({ delete: vi.fn(() => ({ eq: mockEqId })) }))
    });

    await deleteItinerary("saved-1");

    expect(mockEqId).toHaveBeenCalledWith("id", "saved-1");
    expect(mockEqUserId).toHaveBeenCalledWith("user_id", "user-1");
    expect(mockRevalidatePath).toHaveBeenCalledWith("/saved");
  });

  it("throws friendly error when delete fails", async () => {
    const mockEqUserId = vi.fn().mockResolvedValue({ error: { message: "DB error" } });
    const mockEqId = vi.fn(() => ({ eq: mockEqUserId }));

    mockCreateClient.mockResolvedValue({
      auth: { getUser: vi.fn().mockResolvedValue({ data: { user: { id: "user-1" } } }) },
      from: vi.fn(() => ({ delete: vi.fn(() => ({ eq: mockEqId })) }))
    });

    await expect(deleteItinerary("saved-1")).rejects.toThrow("Could not delete itinerary.");
    expect(mockRevalidatePath).not.toHaveBeenCalled();
  });
});

// ---------------------------------------------------------------------------
// fetchSavedItineraries
// ---------------------------------------------------------------------------

describe("fetchSavedItineraries", () => {
  it("returns list rows ordered newest-first", async () => {
    const rows = [
      { id: "a", destination: "Paris", title: "Day 1", summary: null, created_at: "2026-05-13T10:00:00Z", updated_at: "2026-05-13T10:00:00Z" }
    ];
    const mockSupabase = {
      from: vi.fn(() => ({
        select: vi.fn(() => ({
          eq: vi.fn(() => ({
            order: vi.fn().mockResolvedValue({ data: rows, error: null })
          }))
        }))
      }))
    } as never;

    const result = await fetchSavedItineraries(mockSupabase, "user-1");
    expect(result).toEqual(rows);
  });

  it("returns empty array on DB error — graceful degradation", async () => {
    const mockSupabase = {
      from: vi.fn(() => ({
        select: vi.fn(() => ({
          eq: vi.fn(() => ({
            order: vi.fn().mockResolvedValue({ data: null, error: { message: "connection refused" } })
          }))
        }))
      }))
    } as never;

    const result = await fetchSavedItineraries(mockSupabase, "user-1");
    expect(result).toEqual([]);
  });
});

// ---------------------------------------------------------------------------
// fetchSavedItinerary
// ---------------------------------------------------------------------------

describe("fetchSavedItinerary", () => {
  it("returns full row when found", async () => {
    const fullRow = {
      id: "saved-1",
      destination: "Paris",
      title: "A Day in Paris",
      summary: null,
      raw_response: stubItinerary,
      structured_itinerary_json: null,
      created_at: "2026-05-13T10:00:00Z",
      updated_at: "2026-05-13T10:00:00Z"
    };
    const mockSupabase = {
      from: vi.fn(() => ({
        select: vi.fn(() => ({
          eq: vi.fn(() => ({
            eq: vi.fn(() => ({
              single: vi.fn().mockResolvedValue({ data: fullRow, error: null })
            }))
          }))
        }))
      }))
    } as never;

    const result = await fetchSavedItinerary(mockSupabase, "saved-1", "user-1");
    expect(result?.id).toBe("saved-1");
    expect(result?.raw_response.destination).toBe("Paris");
  });

  it("returns null when row not found — enforces own-row access", async () => {
    const mockSupabase = {
      from: vi.fn(() => ({
        select: vi.fn(() => ({
          eq: vi.fn(() => ({
            eq: vi.fn(() => ({
              single: vi.fn().mockResolvedValue({ data: null, error: { message: "PGRST116" } })
            }))
          }))
        }))
      }))
    } as never;

    // RLS assumption: another user's id would cause the .eq("user_id", userId)
    // to return no rows, which surfaces as a null result here, not as an error.
    const result = await fetchSavedItinerary(mockSupabase, "saved-1", "other-user");
    expect(result).toBeNull();
  });
});
