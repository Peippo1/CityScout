import { vi, describe, it, expect, beforeEach } from "vitest";

// Hoisted mocks — must be created before module imports are evaluated.
const { mockRevalidatePath, mockGetUser, mockCreateClient } = vi.hoisted(() => {
  const mockGetUser = vi.fn();

  const mockSingle = vi.fn();
  const mockSelect = vi.fn(() => ({ single: mockSingle }));
  const mockInsert = vi.fn(() => ({ select: mockSelect }));

  const mockEqChain = vi.fn().mockResolvedValue({ error: null });
  const mockFirstEq = vi.fn(() => ({ eq: mockEqChain }));
  const mockDelete = vi.fn(() => ({ eq: mockFirstEq }));

  const mockCreateClient = vi.fn(async () => ({
    auth: { getUser: mockGetUser },
    from: vi.fn(() => ({ insert: mockInsert, delete: mockDelete }))
  }));

  const mockRevalidatePath = vi.fn();

  return { mockRevalidatePath, mockGetUser, mockCreateClient, mockInsert, mockSingle };
});

vi.mock("@/lib/supabase/server", () => ({ createClient: mockCreateClient }));
vi.mock("next/cache", () => ({ revalidatePath: mockRevalidatePath }));

import { saveItinerary, deleteItinerary } from "@/app/actions/itineraries";
import type { PlanItineraryResponse } from "@/types/itinerary";

const stubItinerary: PlanItineraryResponse = {
  destination: "Paris",
  title: "A Day in Paris",
  summary: "Coffee and art.",
  stops: [],
  unmatched_stops: [],
  morning: { title: "Morning", activities: [] },
  afternoon: { title: "Afternoon", activities: [] },
  evening: { title: "Evening", activities: [] },
  notes: [],
  request_id: "req-1",
  generated_at: "2026-05-13T10:00:00Z"
};

describe("saveItinerary", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("throws when not authenticated", async () => {
    mockGetUser.mockResolvedValue({ data: { user: null } });

    await expect(saveItinerary(stubItinerary)).rejects.toThrow("Authentication required.");
    expect(mockRevalidatePath).not.toHaveBeenCalled();
  });

  it("inserts row and returns id on success", async () => {
    mockGetUser.mockResolvedValue({ data: { user: { id: "user-1" } } });
    const mockEqChain = vi.fn().mockResolvedValue({ error: null });
    const mockFirstEq = vi.fn(() => ({ eq: mockEqChain }));
    mockCreateClient.mockResolvedValue({
      auth: { getUser: mockGetUser },
      from: vi.fn(() => ({
        insert: vi.fn(() => ({
          select: vi.fn(() => ({
            single: vi.fn().mockResolvedValue({ data: { id: "saved-1" }, error: null })
          }))
        })),
        delete: vi.fn(() => ({ eq: mockFirstEq }))
      }))
    });

    const result = await saveItinerary(stubItinerary);

    expect(result).toEqual({ id: "saved-1" });
    expect(mockRevalidatePath).toHaveBeenCalledWith("/saved");
  });

  it("throws a friendly error when insert fails", async () => {
    mockGetUser.mockResolvedValue({ data: { user: { id: "user-1" } } });
    mockCreateClient.mockResolvedValue({
      auth: { getUser: mockGetUser },
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

describe("deleteItinerary", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("throws when not authenticated", async () => {
    mockGetUser.mockResolvedValue({ data: { user: null } });

    await expect(deleteItinerary("some-id")).rejects.toThrow("Authentication required.");
    expect(mockRevalidatePath).not.toHaveBeenCalled();
  });

  it("deletes and revalidates on success", async () => {
    mockGetUser.mockResolvedValue({ data: { user: { id: "user-1" } } });
    const mockEqChain = vi.fn().mockResolvedValue({ error: null });
    const mockFirstEq = vi.fn(() => ({ eq: mockEqChain }));
    mockCreateClient.mockResolvedValue({
      auth: { getUser: mockGetUser },
      from: vi.fn(() => ({
        delete: vi.fn(() => ({ eq: mockFirstEq }))
      }))
    });

    await deleteItinerary("saved-1");

    expect(mockEqChain).toHaveBeenCalledWith("user_id", "user-1");
    expect(mockRevalidatePath).toHaveBeenCalledWith("/saved");
  });

  it("throws a friendly error when delete fails", async () => {
    mockGetUser.mockResolvedValue({ data: { user: { id: "user-1" } } });
    const mockEqChain = vi.fn().mockResolvedValue({ error: { message: "DB error" } });
    const mockFirstEq = vi.fn(() => ({ eq: mockEqChain }));
    mockCreateClient.mockResolvedValue({
      auth: { getUser: mockGetUser },
      from: vi.fn(() => ({
        delete: vi.fn(() => ({ eq: mockFirstEq }))
      }))
    });

    await expect(deleteItinerary("saved-1")).rejects.toThrow("Could not delete itinerary.");
    expect(mockRevalidatePath).not.toHaveBeenCalled();
  });
});
