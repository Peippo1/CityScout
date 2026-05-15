import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { vi, describe, it, expect, beforeEach } from "vitest";
import { PlanWorkspace } from "@/components/plan-workspace";
import type { PlanItineraryResponse } from "@/types/itinerary";

vi.mock("@/lib/api", () => {
  class ApiError extends Error {
    status: number;
    code: string;
    requestId?: string;
    constructor(message: string, status: number, code: string, requestId?: string) {
      super(message);
      this.name = "ApiError";
      this.status = status;
      this.code = code;
      this.requestId = requestId;
    }
  }
  return {
    ApiError,
    planItinerary: vi.fn()
  };
});

import { planItinerary } from "@/lib/api";

const mockItinerary: PlanItineraryResponse = {
  destination: "Paris",
  title: "A Day in Paris",
  summary: "A relaxed day through the city.",
  stops: [
    {
      id: "stop-1",
      name: "Café de Flore",
      time_label: "Morning",
      category: "Café",
      description: "Start with coffee on the terrace.",
      latitude: 48.854,
      longitude: 2.332,
      matched_poi_id: "poi-1",
      confidence: 0.9
    },
    {
      id: "stop-2",
      name: "Musée d'Orsay",
      time_label: "Afternoon",
      category: "Museum",
      description: "Impressionist art in a converted train station.",
      latitude: 48.86,
      longitude: 2.327,
      matched_poi_id: "poi-2",
      confidence: 0.95
    }
  ],
  unmatched_stops: [],
  morning: { title: "Morning", activities: ["Café de Flore"] },
  afternoon: { title: "Afternoon", activities: ["Musée d'Orsay"] },
  evening: { title: "Evening", activities: ["Dinner on Île Saint-Louis"] },
  notes: ["Book museum tickets in advance."],
  request_id: "req-abc",
  generated_at: "2026-05-13T10:00:00Z"
};

describe("PlanWorkspace", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    Object.assign(navigator, {
      clipboard: { writeText: vi.fn().mockResolvedValue(undefined) }
    });
  });

  it("renders the planning form and empty itinerary state", () => {
    render(<PlanWorkspace />);

    expect(screen.getByLabelText(/Destination/i)).toHaveValue("Paris");
    expect(screen.getByLabelText(/Notes/i)).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /Generate itinerary/i })).toBeEnabled();
    expect(screen.getByText(/Generate a draft to see a day take shape/i)).toBeInTheDocument();
    expect(screen.getByText(/Map preview/i)).toBeInTheDocument();
  });

  it("shows alpha notice", () => {
    render(<PlanWorkspace />);
    expect(screen.getByText(/public alpha/i)).toBeInTheDocument();
    expect(screen.getByText(/AI-assisted/i)).toBeInTheDocument();
  });

  it("shows loading state while generating", async () => {
    vi.mocked(planItinerary).mockReturnValue(new Promise(() => {}));
    render(<PlanWorkspace />);

    fireEvent.click(screen.getByRole("button", { name: /Generate itinerary/i }));

    await waitFor(() => {
      expect(screen.getByText(/Building your city plan|Checking route flow|Adding practical notes/i)).toBeInTheDocument();
    });
  });

  it("shows friendly error for rate limiting", async () => {
    const { ApiError } = await import("@/lib/api");
    vi.mocked(planItinerary).mockRejectedValue(new (ApiError as never)("rate limited", 429, "rate_limited"));
    render(<PlanWorkspace />);

    fireEvent.click(screen.getByRole("button", { name: /Generate itinerary/i }));

    expect(await screen.findByText(/too many requests/i)).toBeInTheDocument();
    expect(await screen.findByText(/Wait a few minutes/i)).toBeInTheDocument();
  });

  it("shows friendly error when backend is unavailable", async () => {
    const { ApiError } = await import("@/lib/api");
    vi.mocked(planItinerary).mockRejectedValue(
      new (ApiError as never)("upstream error", 503, "upstream_unavailable")
    );
    render(<PlanWorkspace />);

    fireEvent.click(screen.getByRole("button", { name: /Generate itinerary/i }));

    expect(await screen.findByText(/temporarily unavailable/i)).toBeInTheDocument();
  });

  it("shows copy button after generating itinerary", async () => {
    vi.mocked(planItinerary).mockResolvedValue(mockItinerary);
    render(<PlanWorkspace />);

    fireEvent.click(screen.getByRole("button", { name: /Generate itinerary/i }));

    expect(await screen.findByRole("button", { name: /Copy itinerary/i })).toBeInTheDocument();
  });

  it("copy button triggers clipboard write", async () => {
    vi.mocked(planItinerary).mockResolvedValue(mockItinerary);
    render(<PlanWorkspace />);

    fireEvent.click(screen.getByRole("button", { name: /Generate itinerary/i }));

    const copyBtn = await screen.findByRole("button", { name: /Copy itinerary/i });
    fireEvent.click(copyBtn);

    await waitFor(() => {
      expect(navigator.clipboard.writeText).toHaveBeenCalledOnce();
    });
  });

  // ---- Mood-Based Exploration presets ----

  it("renders all 8 exploration mood chips", () => {
    render(<PlanWorkspace />);
    for (const label of ["Mythic", "Quiet", "Romantic", "Lively", "Slow travel", "Food focused", "Historical", "Sea view"]) {
      expect(screen.getByRole("button", { name: label })).toBeInTheDocument();
    }
  });

  it("selects a mood chip on click and shows its description", () => {
    render(<PlanWorkspace />);
    fireEvent.click(screen.getByRole("button", { name: "Mythic" }));
    expect(screen.getByRole("button", { name: "Mythic" })).toHaveClass("bg-city-ink");
    expect(screen.getByText(/Ancient stories/i)).toBeInTheDocument();
  });

  it("deselects a mood chip on second click", () => {
    render(<PlanWorkspace />);
    fireEvent.click(screen.getByRole("button", { name: "Quiet" }));
    fireEvent.click(screen.getByRole("button", { name: "Quiet" }));
    expect(screen.getByRole("button", { name: "Quiet" })).not.toHaveClass("bg-city-ink");
    expect(screen.queryByText(/Fewer crowds/i)).not.toBeInTheDocument();
  });

  it("includes selected mood label in preferences when generating", async () => {
    vi.mocked(planItinerary).mockResolvedValue(mockItinerary);
    render(<PlanWorkspace />);

    fireEvent.click(screen.getByRole("button", { name: "Historical" }));
    fireEvent.click(screen.getByRole("button", { name: /Generate itinerary/i }));

    await waitFor(() => {
      const call = vi.mocked(planItinerary).mock.calls[0][0];
      expect(call.preferences).toContain("Historical");
    });
  });

  it("mood selection persists after generate is clicked", async () => {
    vi.mocked(planItinerary).mockReturnValue(new Promise(() => {}));
    render(<PlanWorkspace />);

    fireEvent.click(screen.getByRole("button", { name: "Romantic" }));
    fireEvent.click(screen.getByRole("button", { name: /Generate itinerary/i }));

    // Mood chip should still be selected
    expect(screen.getByRole("button", { name: "Romantic" })).toHaveClass("bg-city-ink");
  });
});
