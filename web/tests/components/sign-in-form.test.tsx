import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { vi, describe, it, expect, beforeEach } from "vitest";
import { SignInForm } from "@/app/auth/sign-in/sign-in-form";

const mockSignInWithOtp = vi.fn();

vi.mock("@/lib/supabase/client", () => ({
  createClient: vi.fn(() => ({
    auth: { signInWithOtp: mockSignInWithOtp }
  }))
}));

vi.mock("next/navigation", () => ({
  useSearchParams: vi.fn(() => new URLSearchParams())
}));

describe("SignInForm", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("renders email input and submit button", () => {
    render(<SignInForm />);
    expect(screen.getByRole("textbox", { name: /email/i })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /send sign-in link/i })).toBeInTheDocument();
  });

  it("disables submit while loading", async () => {
    mockSignInWithOtp.mockReturnValue(new Promise(() => {}));
    render(<SignInForm />);

    fireEvent.change(screen.getByRole("textbox", { name: /email/i }), {
      target: { value: "test@example.com" }
    });
    fireEvent.click(screen.getByRole("button", { name: /send sign-in link/i }));

    await waitFor(() => {
      expect(screen.getByRole("button", { name: /sending/i })).toBeDisabled();
    });
  });

  it("shows check-your-email state after successful submission", async () => {
    mockSignInWithOtp.mockResolvedValue({ error: null });
    render(<SignInForm />);

    fireEvent.change(screen.getByRole("textbox", { name: /email/i }), {
      target: { value: "test@example.com" }
    });
    fireEvent.click(screen.getByRole("button", { name: /send sign-in link/i }));

    expect(await screen.findByText(/check your email/i)).toBeInTheDocument();
    expect(screen.getByText(/test@example.com/)).toBeInTheDocument();
  });

  it("shows friendly error message when sign-in fails", async () => {
    mockSignInWithOtp.mockResolvedValue({ error: new Error("Rate limited") });
    render(<SignInForm />);

    fireEvent.change(screen.getByRole("textbox", { name: /email/i }), {
      target: { value: "test@example.com" }
    });
    fireEvent.click(screen.getByRole("button", { name: /send sign-in link/i }));

    expect(await screen.findByText(/could not send/i)).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /send sign-in link/i })).toBeEnabled();
  });
});
