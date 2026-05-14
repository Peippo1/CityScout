import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { vi, describe, it, expect, beforeEach } from "vitest";
import { JournalEntryForm } from "@/components/journal-entry-form";
import type { JournalEntry } from "@/types/journal";

const mockCreate = vi.fn();
const mockUpdate = vi.fn();

vi.mock("@/app/actions/journal", () => ({
  createJournalEntry: (...args: unknown[]) => mockCreate(...args),
  updateJournalEntry: (...args: unknown[]) => mockUpdate(...args)
}));

const stubEntry: JournalEntry = {
  id: "entry-1",
  user_id: "user-1",
  itinerary_id: "itin-1",
  destination: "Athens",
  title: "First morning",
  body: "Woke to the sound of bells.",
  mood: "reflective",
  created_at: "2026-05-14T08:00:00Z",
  updated_at: "2026-05-14T08:00:00Z"
};

const noop = () => {};

describe("JournalEntryForm — create mode", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("renders title, body, mood fields and save button", () => {
    render(
      <JournalEntryForm
        itineraryId="itin-1"
        destination="Athens"
        onSuccess={noop}
        onCancel={noop}
      />
    );
    expect(screen.getByPlaceholderText(/short title/i)).toBeInTheDocument();
    expect(screen.getByPlaceholderText(/Write about this place/i)).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /save memory/i })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /cancel/i })).toBeInTheDocument();
  });

  it("renders all 6 mood options", () => {
    render(
      <JournalEntryForm itineraryId="itin-1" destination="Athens" onSuccess={noop} onCancel={noop} />
    );
    for (const mood of ["Reflective", "Adventurous", "Relaxed", "Energetic", "Romantic", "Overwhelmed"]) {
      expect(screen.getByRole("button", { name: mood })).toBeInTheDocument();
    }
  });

  it("toggles mood on click and deselects on second click", () => {
    render(
      <JournalEntryForm itineraryId="itin-1" destination="Athens" onSuccess={noop} onCancel={noop} />
    );
    const relaxed = screen.getByRole("button", { name: "Relaxed" });
    fireEvent.click(relaxed);
    expect(relaxed).toHaveClass("bg-city-ink");
    fireEvent.click(relaxed);
    expect(relaxed).not.toHaveClass("bg-city-ink");
  });

  it("shows error if body is empty on submit", async () => {
    render(
      <JournalEntryForm itineraryId="itin-1" destination="Athens" onSuccess={noop} onCancel={noop} />
    );
    fireEvent.click(screen.getByRole("button", { name: /save memory/i }));
    expect(await screen.findByText(/write something before saving/i)).toBeInTheDocument();
    expect(mockCreate).not.toHaveBeenCalled();
  });

  it("calls createJournalEntry and invokes onSuccess", async () => {
    mockCreate.mockResolvedValue({ id: "new-entry" });
    const onSuccess = vi.fn();

    render(
      <JournalEntryForm itineraryId="itin-1" destination="Athens" onSuccess={onSuccess} onCancel={noop} />
    );
    fireEvent.change(screen.getByPlaceholderText(/Write about this place/i), {
      target: { value: "A beautiful morning on the Acropolis." }
    });
    fireEvent.click(screen.getByRole("button", { name: /save memory/i }));

    await waitFor(() => {
      expect(mockCreate).toHaveBeenCalledOnce();
      expect(onSuccess).toHaveBeenCalledOnce();
    });
  });

  it("shows error message on save failure", async () => {
    mockCreate.mockRejectedValue(new Error("DB error"));

    render(
      <JournalEntryForm itineraryId="itin-1" destination="Athens" onSuccess={noop} onCancel={noop} />
    );
    fireEvent.change(screen.getByPlaceholderText(/Write about this place/i), {
      target: { value: "Something went wrong." }
    });
    fireEvent.click(screen.getByRole("button", { name: /save memory/i }));

    expect(await screen.findByText(/could not save entry/i)).toBeInTheDocument();
  });

  it("calls onCancel when cancel is clicked", () => {
    const onCancel = vi.fn();
    render(
      <JournalEntryForm itineraryId="itin-1" destination="Athens" onSuccess={noop} onCancel={onCancel} />
    );
    fireEvent.click(screen.getByRole("button", { name: /cancel/i }));
    expect(onCancel).toHaveBeenCalledOnce();
  });
});

describe("JournalEntryForm — edit mode", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("pre-fills fields from existing entry", () => {
    render(
      <JournalEntryForm
        itineraryId="itin-1"
        destination="Athens"
        entry={stubEntry}
        onSuccess={noop}
        onCancel={noop}
      />
    );
    expect(screen.getByDisplayValue("First morning")).toBeInTheDocument();
    expect(screen.getByDisplayValue("Woke to the sound of bells.")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /save changes/i })).toBeInTheDocument();
  });

  it("calls updateJournalEntry and invokes onSuccess", async () => {
    mockUpdate.mockResolvedValue(undefined);
    const onSuccess = vi.fn();

    render(
      <JournalEntryForm
        itineraryId="itin-1"
        destination="Athens"
        entry={stubEntry}
        onSuccess={onSuccess}
        onCancel={noop}
      />
    );
    fireEvent.change(screen.getByDisplayValue("Woke to the sound of bells."), {
      target: { value: "Updated body." }
    });
    fireEvent.click(screen.getByRole("button", { name: /save changes/i }));

    await waitFor(() => {
      expect(mockUpdate).toHaveBeenCalledOnce();
      expect(onSuccess).toHaveBeenCalledOnce();
    });
  });
});
