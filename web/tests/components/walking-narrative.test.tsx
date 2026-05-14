import { render, screen } from "@testing-library/react";
import { describe, it, expect } from "vitest";
import { WalkingNarrative } from "@/components/walking-narrative";

describe("WalkingNarrative", () => {
  it("renders narrative for Athens", () => {
    render(<WalkingNarrative destination="Athens" />);
    expect(screen.getByText(/Walking narrative/i)).toBeInTheDocument();
    expect(screen.getByText(/Athens: the layers beneath/i)).toBeInTheDocument();
  });

  it("renders narrative for Acropolis", () => {
    render(<WalkingNarrative destination="Acropolis" />);
    expect(screen.getByText(/The Acropolis: stone and memory/i)).toBeInTheDocument();
  });

  it("renders narrative for Ancient Agora via alias", () => {
    render(<WalkingNarrative destination="Agora of Athens" />);
    expect(screen.getByText(/The Agora: where Athens argued/i)).toBeInTheDocument();
  });

  it("renders nothing for an unknown destination", () => {
    const { container } = render(<WalkingNarrative destination="London" />);
    expect(container.firstChild).toBeNull();
  });

  it("renders nothing for empty string", () => {
    const { container } = render(<WalkingNarrative destination="" />);
    expect(container.firstChild).toBeNull();
  });

  it("matches case-insensitively", () => {
    render(<WalkingNarrative destination="ATHENS" />);
    expect(screen.getByText(/Walking narrative/i)).toBeInTheDocument();
  });

  it("shows duration in minutes", () => {
    render(<WalkingNarrative destination="Athens" />);
    expect(screen.getByText(/90 min/i)).toBeInTheDocument();
  });

  it("renders all stops for Athens", () => {
    render(<WalkingNarrative destination="Athens" />);
    expect(screen.getByText("Monastiraki Square")).toBeInTheDocument();
    expect(screen.getByText("The Parthenon")).toBeInTheDocument();
  });

  it("renders look-for hints when present", () => {
    render(<WalkingNarrative destination="Athens" />);
    const hints = screen.getAllByText(/Look for:/i);
    expect(hints.length).toBeGreaterThan(0);
  });

  it("renders stop type badges", () => {
    render(<WalkingNarrative destination="Ancient Agora" />);
    expect(screen.getByText("Landmark")).toBeInTheDocument();
    expect(screen.getByText("History")).toBeInTheDocument();
  });
});
