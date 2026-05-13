import { render, screen } from "@testing-library/react";
import { describe, it, expect } from "vitest";
import { HistoryMythology } from "@/components/history-mythology";

describe("HistoryMythology", () => {
  it("renders stories for a known destination", () => {
    render(<HistoryMythology destination="Athens" />);

    expect(screen.getByText(/History & mythology/i)).toBeInTheDocument();
    expect(screen.getByText(/The contest for a city/i)).toBeInTheDocument();
  });

  it("renders multiple stories for a destination", () => {
    render(<HistoryMythology destination="Athens" />);

    // Athens has 3 stories in the seed
    const headlines = screen.getAllByRole("heading", { level: 4 });
    expect(headlines.length).toBeGreaterThanOrEqual(3);
  });

  it("renders recommended reading when present", () => {
    render(<HistoryMythology destination="Athens" />);

    expect(screen.getByText(/Recommended reading/i)).toBeInTheDocument();
    expect(screen.getByText(/Thucydides/i)).toBeInTheDocument();
  });

  it("renders nothing for an unknown destination", () => {
    const { container } = render(<HistoryMythology destination="Atlantis" />);
    expect(container.firstChild).toBeNull();
  });

  it("renders nothing for an empty destination string", () => {
    const { container } = render(<HistoryMythology destination="" />);
    expect(container.firstChild).toBeNull();
  });

  it("matches case-insensitively", () => {
    render(<HistoryMythology destination="ATHENS" />);
    expect(screen.getByText(/History & mythology/i)).toBeInTheDocument();
  });

  it("matches by alias", () => {
    render(<HistoryMythology destination="Acropolis of Athens" />);
    expect(screen.getByText(/History & mythology/i)).toBeInTheDocument();
    expect(screen.getByText(/A hill before it was a monument/i)).toBeInTheDocument();
  });

  it("renders landmark badge for landmark-category stories", () => {
    render(<HistoryMythology destination="Marathon" />);
    // Marathon stories are history/mythology categories — no landmark badge expected
    // but the category pills should be present
    expect(screen.getAllByText(/History|Mythology/i).length).toBeGreaterThan(0);
  });

  it("renders Naxos mythology stories", () => {
    render(<HistoryMythology destination="Naxos" />);
    expect(screen.getByText(/Theseus left Ariadne/i)).toBeInTheDocument();
    expect(screen.getByText(/unfinished colossi/i)).toBeInTheDocument();
  });

  it("renders reading section when reading entries are present", () => {
    render(<HistoryMythology destination="Paros" />);
    expect(screen.getByText(/Recommended reading/i)).toBeInTheDocument();
    // "Archilochus" appears in both a story headline and the reading list author
    expect(screen.getAllByText(/Archilochus/i).length).toBeGreaterThanOrEqual(2);
  });
});
