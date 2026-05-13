import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { vi, describe, it, expect, beforeEach } from "vitest";
import { SignOutButton } from "@/components/sign-out-button";

const mockSignOut = vi.fn().mockResolvedValue({ error: null });
const mockRefresh = vi.fn();

vi.mock("@/lib/supabase/client", () => ({
  createClient: vi.fn(() => ({
    auth: { signOut: mockSignOut }
  }))
}));

vi.mock("next/navigation", () => ({
  useRouter: vi.fn(() => ({ refresh: mockRefresh }))
}));

describe("SignOutButton", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockSignOut.mockResolvedValue({ error: null });
  });

  it("renders a sign out button", () => {
    render(<SignOutButton />);
    expect(screen.getByRole("button", { name: /sign out/i })).toBeInTheDocument();
  });

  it("calls signOut then refreshes the router on click", async () => {
    render(<SignOutButton />);
    fireEvent.click(screen.getByRole("button", { name: /sign out/i }));
    await waitFor(() => {
      expect(mockSignOut).toHaveBeenCalledOnce();
      expect(mockRefresh).toHaveBeenCalledOnce();
    });
  });
});
