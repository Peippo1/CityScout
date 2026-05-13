import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { vi, describe, it, expect, beforeEach } from "vitest";
import { SaveItineraryButton } from "@/components/save-itinerary-button";
import type { PlanItineraryResponse } from "@/types/itinerary";

const mockSaveItinerary = vi.fn();

vi.mock("@/app/actions/itineraries", () => ({
  saveItinerary: (...args: unknown[]) => mockSaveItinerary(...args)
}));

const stubItinerary: PlanItineraryResponse = {
  destination: "Paris",
  title: "A Day in Paris",
  summary: null,
  stops: [],
  unmatched_stops: [],
  morning: { title: "Morning", activities: [] },
  afternoon: { title: "Afternoon", activities: [] },
  evening: { title: "Evening", activities: [] },
  notes: []
};

const noop = () => {};

describe("SaveItineraryButton", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("shows sign-in link when userId is null", () => {
    render(
      <SaveItineraryButton
        itinerary={stubItinerary}
        userId={null}
        savedId={null}
        onSaved={noop}
      />
    );
    const link = screen.getByRole("link", { name: /sign in to save/i });
    expect(link).toHaveAttribute("href", "/auth/sign-in?next=/plan");
  });

  it("shows save button when authenticated and not yet saved", () => {
    render(
      <SaveItineraryButton
        itinerary={stubItinerary}
        userId="user-1"
        savedId={null}
        onSaved={noop}
      />
    );
    expect(screen.getByRole("button", { name: /save itinerary/i })).toBeEnabled();
  });

  it("shows saved link when savedId is set", () => {
    render(
      <SaveItineraryButton
        itinerary={stubItinerary}
        userId="user-1"
        savedId="saved-abc"
        onSaved={noop}
      />
    );
    const link = screen.getByRole("link", { name: /saved/i });
    expect(link).toHaveAttribute("href", "/saved");
  });

  it("shows loading state and calls onSaved on success", async () => {
    mockSaveItinerary.mockResolvedValue({ id: "new-id" });
    const onSaved = vi.fn();

    render(
      <SaveItineraryButton
        itinerary={stubItinerary}
        userId="user-1"
        savedId={null}
        onSaved={onSaved}
      />
    );

    fireEvent.click(screen.getByRole("button", { name: /save itinerary/i }));

    await waitFor(() => {
      expect(onSaved).toHaveBeenCalledWith("new-id");
    });
  });

  it("shows try-again button on save failure", async () => {
    mockSaveItinerary.mockRejectedValue(new Error("DB error"));

    render(
      <SaveItineraryButton
        itinerary={stubItinerary}
        userId="user-1"
        savedId={null}
        onSaved={noop}
      />
    );

    fireEvent.click(screen.getByRole("button", { name: /save itinerary/i }));

    expect(await screen.findByRole("button", { name: /try again/i })).toBeInTheDocument();
  });
});
