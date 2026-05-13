import { vi, describe, it, expect, beforeEach } from "vitest";

const mockExchangeCodeForSession = vi.fn();

vi.mock("next/headers", () => ({
  cookies: vi.fn().mockResolvedValue({
    getAll: vi.fn(() => []),
    set: vi.fn()
  })
}));

vi.mock("@supabase/ssr", () => ({
  createServerClient: vi.fn(() => ({
    auth: { exchangeCodeForSession: mockExchangeCodeForSession }
  }))
}));

import { GET } from "@/app/auth/callback/route";

describe("GET /auth/callback", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("exchanges code and redirects to / by default", async () => {
    mockExchangeCodeForSession.mockResolvedValue({ error: null });

    const response = await GET(new Request("http://localhost:3000/auth/callback?code=abc123"));

    expect(mockExchangeCodeForSession).toHaveBeenCalledWith("abc123");
    expect(response.status).toBe(307);
    expect(response.headers.get("location")).toBe("http://localhost:3000/");
  });

  it("redirects to next param after successful exchange", async () => {
    mockExchangeCodeForSession.mockResolvedValue({ error: null });

    const response = await GET(
      new Request("http://localhost:3000/auth/callback?code=abc123&next=%2Fsaved")
    );

    expect(response.headers.get("location")).toBe("http://localhost:3000/saved");
  });

  it("blocks open redirect — falls back to /", async () => {
    mockExchangeCodeForSession.mockResolvedValue({ error: null });

    const response = await GET(
      new Request(
        "http://localhost:3000/auth/callback?code=abc123&next=https%3A%2F%2Fevil.com"
      )
    );

    expect(response.headers.get("location")).toBe("http://localhost:3000/");
  });

  it("redirects to sign-in with error when exchange fails", async () => {
    mockExchangeCodeForSession.mockResolvedValue({ error: new Error("Invalid code") });

    const response = await GET(new Request("http://localhost:3000/auth/callback?code=bad"));

    expect(response.status).toBe(307);
    expect(response.headers.get("location")).toContain("/auth/sign-in");
    expect(response.headers.get("location")).toContain("error=callback_failed");
  });

  it("redirects to sign-in when no code is present", async () => {
    const response = await GET(new Request("http://localhost:3000/auth/callback"));

    expect(mockExchangeCodeForSession).not.toHaveBeenCalled();
    expect(response.headers.get("location")).toContain("/auth/sign-in");
    expect(response.headers.get("location")).toContain("error=callback_failed");
  });
});
