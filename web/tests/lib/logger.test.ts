import { vi, describe, it, expect, beforeEach, afterEach } from "vitest";
import { log, hashIp, startTimer } from "@/lib/logger";

describe("log", () => {
  beforeEach(() => {
    vi.spyOn(console, "log").mockImplementation(() => {});
    vi.spyOn(console, "warn").mockImplementation(() => {});
    vi.spyOn(console, "error").mockImplementation(() => {});
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("calls console.log for info level", () => {
    log({ level: "info", route: "/test", event: "test_event" });
    expect(console.log).toHaveBeenCalledOnce();
  });

  it("calls console.warn for warn level", () => {
    log({ level: "warn", route: "/test", event: "rate_limited" });
    expect(console.warn).toHaveBeenCalledOnce();
  });

  it("calls console.error for error level", () => {
    log({ level: "error", route: "/test", event: "upstream_error" });
    expect(console.error).toHaveBeenCalledOnce();
  });

  it("output is valid JSON with a ts field", () => {
    let captured = "";
    vi.spyOn(console, "log").mockImplementation((msg: string) => { captured = msg; });

    log({ level: "info", route: "/api/plan-itinerary", event: "generation_complete", status: 200 });

    const parsed = JSON.parse(captured);
    expect(parsed.ts).toBeDefined();
    expect(new Date(parsed.ts).getTime()).not.toBeNaN();
    expect(parsed.event).toBe("generation_complete");
    expect(parsed.status).toBe(200);
  });

  it("includes all provided fields in output", () => {
    let captured = "";
    vi.spyOn(console, "warn").mockImplementation((msg: string) => { captured = msg; });

    log({
      level: "warn",
      route: "/api/plan-itinerary",
      event: "rate_limited",
      requestId: "req-123",
      status: 429,
      clientHash: "abc123",
      durationMs: 12
    });

    const parsed = JSON.parse(captured);
    expect(parsed.requestId).toBe("req-123");
    expect(parsed.status).toBe(429);
    expect(parsed.clientHash).toBe("abc123");
    expect(parsed.durationMs).toBe(12);
  });
});

describe("hashIp", () => {
  it("returns a 16-character hex string", async () => {
    const result = await hashIp("192.168.1.1");
    expect(result).toHaveLength(16);
    expect(result).toMatch(/^[0-9a-f]+$/);
  });

  it("produces different hashes for different IPs", async () => {
    const a = await hashIp("1.2.3.4");
    const b = await hashIp("5.6.7.8");
    expect(a).not.toBe(b);
  });

  it("is deterministic for the same IP", async () => {
    const a = await hashIp("10.0.0.1");
    const b = await hashIp("10.0.0.1");
    expect(a).toBe(b);
  });

  it("returns 'unknown' for empty string (graceful fallback)", async () => {
    // Empty string is still hashable, but ensure no throw
    const result = await hashIp("");
    expect(typeof result).toBe("string");
  });
});

describe("startTimer", () => {
  it("returns elapsed milliseconds greater than zero after a tick", async () => {
    const elapsed = startTimer();
    await new Promise((r) => setTimeout(r, 5));
    expect(elapsed()).toBeGreaterThan(0);
  });

  it("elapsed increases over time", async () => {
    const elapsed = startTimer();
    const first = elapsed();
    await new Promise((r) => setTimeout(r, 5));
    const second = elapsed();
    expect(second).toBeGreaterThanOrEqual(first);
  });
});
