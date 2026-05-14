import { render, screen, fireEvent } from "@testing-library/react";
import { vi, describe, it, expect } from "vitest";
import { JournalEntryCard } from "@/components/journal-entry-card";
import type { JournalEntry } from "@/types/journal";

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

describe("JournalEntryCard", () => {
  it("renders title, body, and mood", () => {
    render(<JournalEntryCard entry={stubEntry} onEdit={() => {}} onDelete={() => {}} />);
    expect(screen.getByText("First morning")).toBeInTheDocument();
    expect(screen.getByText("Woke to the sound of bells.")).toBeInTheDocument();
    expect(screen.getByText("Reflective")).toBeInTheDocument();
  });

  it("omits title when null", () => {
    render(
      <JournalEntryCard
        entry={{ ...stubEntry, title: null }}
        onEdit={() => {}}
        onDelete={() => {}}
      />
    );
    expect(screen.queryByText("First morning")).not.toBeInTheDocument();
  });

  it("omits mood badge when null", () => {
    render(
      <JournalEntryCard
        entry={{ ...stubEntry, mood: null }}
        onEdit={() => {}}
        onDelete={() => {}}
      />
    );
    expect(screen.queryByText("Reflective")).not.toBeInTheDocument();
  });

  it("calls onEdit when Edit is clicked", () => {
    const onEdit = vi.fn();
    render(<JournalEntryCard entry={stubEntry} onEdit={onEdit} onDelete={() => {}} />);
    fireEvent.click(screen.getByRole("button", { name: /edit/i }));
    expect(onEdit).toHaveBeenCalledOnce();
  });

  it("calls onDelete with the entry id", () => {
    const onDelete = vi.fn();
    render(<JournalEntryCard entry={stubEntry} onEdit={() => {}} onDelete={onDelete} />);
    fireEvent.click(screen.getByRole("button", { name: /delete/i }));
    expect(onDelete).toHaveBeenCalledWith("entry-1");
  });

  it("disables edit and delete when isDeleting", () => {
    render(<JournalEntryCard entry={stubEntry} onEdit={() => {}} onDelete={() => {}} isDeleting />);
    expect(screen.getByRole("button", { name: /edit/i })).toBeDisabled();
    expect(screen.getByRole("button", { name: /delete/i })).toBeDisabled();
  });

  it("shows edited indicator when updated_at differs from created_at", () => {
    render(
      <JournalEntryCard
        entry={{ ...stubEntry, updated_at: "2026-05-14T12:00:00Z" }}
        onEdit={() => {}}
        onDelete={() => {}}
      />
    );
    expect(screen.getByText(/edited/i)).toBeInTheDocument();
  });

  it("does not show edited indicator when timestamps match", () => {
    render(<JournalEntryCard entry={stubEntry} onEdit={() => {}} onDelete={() => {}} />);
    expect(screen.queryByText(/edited/i)).not.toBeInTheDocument();
  });
});
