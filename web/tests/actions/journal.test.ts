import { vi, describe, it, expect, beforeEach } from "vitest";

// ---------------------------------------------------------------------------
// RLS assumptions for journal_entries:
//
//   journal_select_own — SELECT: auth.uid() = user_id
//   journal_insert_own — INSERT: auth.uid() = user_id (with check)
//   journal_update_own — UPDATE: auth.uid() = user_id
//   journal_delete_own — DELETE: auth.uid() = user_id
//
// These tests validate the server-side auth guards in our Server Actions.
// All mutations also filter by user_id as belt-and-suspenders so that
// a misconfigured RLS policy cannot escalate to cross-user mutations.
// ---------------------------------------------------------------------------

const { mockRevalidatePath, mockGetUser, mockCreateClient } = vi.hoisted(() => {
  const mockGetUser = vi.fn();
  const mockCreateClient = vi.fn();
  const mockRevalidatePath = vi.fn();
  return { mockRevalidatePath, mockGetUser, mockCreateClient };
});

vi.mock("@/lib/supabase/server", () => ({ createClient: mockCreateClient }));
vi.mock("next/cache", () => ({ revalidatePath: mockRevalidatePath }));

import { createJournalEntry, updateJournalEntry, deleteJournalEntry } from "@/app/actions/journal";

const ITINERARY_ID = "itin-1";
const ENTRY_ID = "entry-1";
const USER_ID = "user-1";

const validCreateInput = {
  itinerary_id: ITINERARY_ID,
  destination: "Athens",
  title: "First morning",
  body: "Woke to the sound of bells from the church below the Acropolis.",
  mood: "reflective" as const
};

function supabaseWith(overrides: Record<string, unknown> = {}) {
  return {
    auth: { getUser: mockGetUser },
    ...overrides
  };
}

describe("createJournalEntry", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("throws when unauthenticated", async () => {
    mockGetUser.mockResolvedValue({ data: { user: null } });
    mockCreateClient.mockResolvedValue(supabaseWith());

    await expect(createJournalEntry(validCreateInput)).rejects.toThrow("Authentication required.");
    expect(mockRevalidatePath).not.toHaveBeenCalled();
  });

  it("throws when body is empty", async () => {
    mockGetUser.mockResolvedValue({ data: { user: { id: USER_ID } } });
    mockCreateClient.mockResolvedValue(supabaseWith());

    await expect(
      createJournalEntry({ ...validCreateInput, body: "   " })
    ).rejects.toThrow("body cannot be empty");
  });

  it("inserts entry and returns id", async () => {
    mockGetUser.mockResolvedValue({ data: { user: { id: USER_ID } } });
    mockCreateClient.mockResolvedValue(
      supabaseWith({
        from: vi.fn(() => ({
          insert: vi.fn(() => ({
            select: vi.fn(() => ({
              single: vi.fn().mockResolvedValue({ data: { id: ENTRY_ID }, error: null })
            }))
          }))
        }))
      })
    );

    const result = await createJournalEntry(validCreateInput);
    expect(result).toEqual({ id: ENTRY_ID });
    expect(mockRevalidatePath).toHaveBeenCalledWith(`/saved/${ITINERARY_ID}`);
  });

  it("strips invalid mood values", async () => {
    mockGetUser.mockResolvedValue({ data: { user: { id: USER_ID } } });
    const mockInsert = vi.fn(() => ({
      select: vi.fn(() => ({
        single: vi.fn().mockResolvedValue({ data: { id: ENTRY_ID }, error: null })
      }))
    }));
    mockCreateClient.mockResolvedValue(
      supabaseWith({ from: vi.fn(() => ({ insert: mockInsert })) })
    );

    await createJournalEntry({ ...validCreateInput, mood: "furious" as never });

    const inserted = mockInsert.mock.calls[0][0] as Record<string, unknown>;
    expect(inserted.mood).toBeNull();
  });

  it("throws friendly error on DB failure", async () => {
    mockGetUser.mockResolvedValue({ data: { user: { id: USER_ID } } });
    mockCreateClient.mockResolvedValue(
      supabaseWith({
        from: vi.fn(() => ({
          insert: vi.fn(() => ({
            select: vi.fn(() => ({
              single: vi.fn().mockResolvedValue({ data: null, error: { message: "DB error" } })
            }))
          }))
        }))
      })
    );

    await expect(createJournalEntry(validCreateInput)).rejects.toThrow("Could not save journal entry.");
    expect(mockRevalidatePath).not.toHaveBeenCalled();
  });
});

describe("updateJournalEntry", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("throws when unauthenticated", async () => {
    mockGetUser.mockResolvedValue({ data: { user: null } });
    mockCreateClient.mockResolvedValue(supabaseWith());

    await expect(
      updateJournalEntry(ENTRY_ID, ITINERARY_ID, { title: null, body: "Updated.", mood: null })
    ).rejects.toThrow("Authentication required.");
  });

  it("updates entry and revalidates", async () => {
    mockGetUser.mockResolvedValue({ data: { user: { id: USER_ID } } });
    const mockEqUser = vi.fn().mockResolvedValue({ error: null });
    const mockEqId = vi.fn(() => ({ eq: mockEqUser }));
    mockCreateClient.mockResolvedValue(
      supabaseWith({
        from: vi.fn(() => ({
          update: vi.fn(() => ({ eq: mockEqId }))
        }))
      })
    );

    await updateJournalEntry(ENTRY_ID, ITINERARY_ID, { title: "New title", body: "Updated body.", mood: "relaxed" });

    expect(mockEqId).toHaveBeenCalledWith("id", ENTRY_ID);
    expect(mockEqUser).toHaveBeenCalledWith("user_id", USER_ID);
    expect(mockRevalidatePath).toHaveBeenCalledWith(`/saved/${ITINERARY_ID}`);
  });
});

describe("deleteJournalEntry", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("throws when unauthenticated", async () => {
    mockGetUser.mockResolvedValue({ data: { user: null } });
    mockCreateClient.mockResolvedValue(supabaseWith());

    await expect(deleteJournalEntry(ENTRY_ID, ITINERARY_ID)).rejects.toThrow("Authentication required.");
    expect(mockRevalidatePath).not.toHaveBeenCalled();
  });

  it("deletes by id and user_id, then revalidates", async () => {
    mockGetUser.mockResolvedValue({ data: { user: { id: USER_ID } } });
    const mockEqUser = vi.fn().mockResolvedValue({ error: null });
    const mockEqId = vi.fn(() => ({ eq: mockEqUser }));
    mockCreateClient.mockResolvedValue(
      supabaseWith({
        from: vi.fn(() => ({
          delete: vi.fn(() => ({ eq: mockEqId }))
        }))
      })
    );

    await deleteJournalEntry(ENTRY_ID, ITINERARY_ID);

    expect(mockEqId).toHaveBeenCalledWith("id", ENTRY_ID);
    expect(mockEqUser).toHaveBeenCalledWith("user_id", USER_ID);
    expect(mockRevalidatePath).toHaveBeenCalledWith(`/saved/${ITINERARY_ID}`);
  });

  it("throws friendly error on DB failure", async () => {
    mockGetUser.mockResolvedValue({ data: { user: { id: USER_ID } } });
    const mockEqUser = vi.fn().mockResolvedValue({ error: { message: "DB error" } });
    const mockEqId = vi.fn(() => ({ eq: mockEqUser }));
    mockCreateClient.mockResolvedValue(
      supabaseWith({
        from: vi.fn(() => ({
          delete: vi.fn(() => ({ eq: mockEqId }))
        }))
      })
    );

    await expect(deleteJournalEntry(ENTRY_ID, ITINERARY_ID)).rejects.toThrow("Could not delete journal entry.");
    expect(mockRevalidatePath).not.toHaveBeenCalled();
  });
});
