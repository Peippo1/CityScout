import { render, screen, act } from "@testing-library/react";
import { vi, describe, it, expect, beforeEach, afterEach } from "vitest";
import { Toast } from "@/components/toast";

describe("Toast", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("renders a success toast message", () => {
    render(
      <Toast message="Itinerary deleted." variant="success" toastKey={1} onDismiss={() => {}} />
    );
    expect(screen.getByRole("status")).toHaveTextContent("Itinerary deleted.");
  });

  it("renders an error toast message", () => {
    render(
      <Toast
        message="Could not save itinerary."
        variant="error"
        toastKey={1}
        onDismiss={() => {}}
      />
    );
    expect(screen.getByRole("status")).toHaveTextContent("Could not save itinerary.");
  });

  it("calls onDismiss after 3 seconds for success", () => {
    const onDismiss = vi.fn();
    render(
      <Toast message="Deleted." variant="success" toastKey={1} onDismiss={onDismiss} />
    );
    expect(onDismiss).not.toHaveBeenCalled();
    act(() => { vi.advanceTimersByTime(3000); });
    expect(onDismiss).toHaveBeenCalledOnce();
  });

  it("calls onDismiss after 5 seconds for error", () => {
    const onDismiss = vi.fn();
    render(
      <Toast message="Failed." variant="error" toastKey={1} onDismiss={onDismiss} />
    );
    act(() => { vi.advanceTimersByTime(4999); });
    expect(onDismiss).not.toHaveBeenCalled();
    act(() => { vi.advanceTimersByTime(1); });
    expect(onDismiss).toHaveBeenCalledOnce();
  });

  it("resets dismiss timer when toastKey changes", () => {
    const onDismiss = vi.fn();
    const { rerender } = render(
      <Toast message="First." variant="success" toastKey={1} onDismiss={onDismiss} />
    );
    act(() => { vi.advanceTimersByTime(2000); });
    // Re-render with same message but new key — timer resets.
    rerender(
      <Toast message="First." variant="success" toastKey={2} onDismiss={onDismiss} />
    );
    act(() => { vi.advanceTimersByTime(2000); });
    expect(onDismiss).not.toHaveBeenCalled();
    act(() => { vi.advanceTimersByTime(1000); });
    expect(onDismiss).toHaveBeenCalledOnce();
  });
});
