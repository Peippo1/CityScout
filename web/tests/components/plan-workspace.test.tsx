import { render, screen } from "@testing-library/react";
import { PlanWorkspace } from "@/components/plan-workspace";

describe("PlanWorkspace", () => {
  it("renders the planning form and empty itinerary state", () => {
    render(<PlanWorkspace />);

    expect(screen.getByLabelText(/Destination/i)).toHaveValue("Paris");
    expect(screen.getByLabelText(/Notes/i)).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /Generate itinerary/i })).toBeEnabled();
    expect(screen.getByText(/Generate a draft to see a city timeline/i)).toBeInTheDocument();
    expect(screen.getByText(/Map preview/i)).toBeInTheDocument();
  });
});
