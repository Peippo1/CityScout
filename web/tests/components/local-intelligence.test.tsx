import { render, screen } from "@testing-library/react";
import { describe, it, expect } from "vitest";
import { LocalIntelligence } from "@/components/local-intelligence";

describe("LocalIntelligence", () => {
  it("renders tips for a known destination", () => {
    render(<LocalIntelligence destination="Paris" />);

    expect(screen.getByText(/Local intelligence/i)).toBeInTheDocument();
    // At least one category heading should appear
    expect(screen.getByText(/Culture/i)).toBeInTheDocument();
  });

  it("renders nothing for an unknown destination", () => {
    const { container } = render(<LocalIntelligence destination="Atlantis" />);
    expect(container.firstChild).toBeNull();
  });

  it("matches case-insensitively", () => {
    render(<LocalIntelligence destination="TOKYO" />);
    expect(screen.getByText(/Local intelligence/i)).toBeInTheDocument();
  });

  it("matches by alias", () => {
    render(<LocalIntelligence destination="nyc" />);
    expect(screen.getByText(/Local intelligence/i)).toBeInTheDocument();
  });

  it("renders nothing for an empty destination string", () => {
    const { container } = render(<LocalIntelligence destination="" />);
    expect(container.firstChild).toBeNull();
  });

  it("shows transport tips when present", () => {
    render(<LocalIntelligence destination="London" />);
    expect(screen.getByText(/Getting around/i)).toBeInTheDocument();
  });

  it("shows food tips when present", () => {
    render(<LocalIntelligence destination="Rome" />);
    expect(screen.getByText(/Food & drink/i)).toBeInTheDocument();
  });
});
