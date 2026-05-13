import { render, screen, fireEvent } from "@testing-library/react";
import { vi, describe, it, expect } from "vitest";
import { SavedItineraryCard } from "@/components/saved-itinerary-card";
import type { SavedItineraryRow } from "@/types/saved-itinerary";

const stubItem: SavedItineraryRow = {
  id: "item-1",
  destination: "Paris",
  title: "A Relaxed Day in Paris",
  summary: "Coffee, art, and a long walk.",
  created_at: "2026-05-13T10:00:00Z"
};

describe("SavedItineraryCard", () => {
  it("renders destination, title, and summary", () => {
    render(<SavedItineraryCard item={stubItem} onDelete={() => {}} />);

    expect(screen.getByText("Paris")).toBeInTheDocument();
    expect(screen.getByText("A Relaxed Day in Paris")).toBeInTheDocument();
    expect(screen.getByText("Coffee, art, and a long walk.")).toBeInTheDocument();
  });

  it("Open link points to /plan?id=<id>", () => {
    render(<SavedItineraryCard item={stubItem} onDelete={() => {}} />);
    expect(screen.getByRole("link", { name: /open/i })).toHaveAttribute(
      "href",
      "/plan?id=item-1"
    );
  });

  it("calls onDelete with the correct id when delete is clicked", () => {
    const onDelete = vi.fn();
    render(<SavedItineraryCard item={stubItem} onDelete={onDelete} />);

    fireEvent.click(screen.getByRole("button", { name: /delete/i }));

    expect(onDelete).toHaveBeenCalledWith("item-1");
  });

  it("disables delete button and reduces opacity when isDeleting", () => {
    render(<SavedItineraryCard item={stubItem} onDelete={() => {}} isDeleting />);

    expect(screen.getByRole("button", { name: /delete/i })).toBeDisabled();
  });

  it("omits summary when null", () => {
    render(<SavedItineraryCard item={{ ...stubItem, summary: null }} onDelete={() => {}} />);
    expect(screen.queryByText("Coffee, art, and a long walk.")).not.toBeInTheDocument();
  });
});
