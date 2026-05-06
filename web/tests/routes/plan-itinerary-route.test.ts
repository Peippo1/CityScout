// @vitest-environment node

import { NextRequest } from "next/server";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const API_BASE_URL = "http://backend.test";
const APP_SHARED_SECRET = "server-only-secret";
const REQUEST_ID = "request-123";
const BACKEND_REQUEST_ID = "backend-456";

async function loadRouteModule() {
  vi.resetModules();
  return import("@/app/api/plan-itinerary/route");
}

function buildRequest(body: unknown, method: string = "POST") {
  const init: RequestInit = {
    method,
    headers: {
      "X-Request-Id": REQUEST_ID
    }
  };

  if (method === "POST") {
    init.headers = {
      ...init.headers,
      "content-type": "application/json"
    };
    init.body = JSON.stringify(body);
  }

  return new NextRequest("http://localhost/api/plan-itinerary", init);
}

describe("POST /api/plan-itinerary", () => {
  beforeEach(() => {
    process.env.CITYSCOUT_API_BASE_URL = API_BASE_URL;
    process.env.CITYSCOUT_APP_SHARED_SECRET = APP_SHARED_SECRET;
  });

  afterEach(() => {
    delete process.env.CITYSCOUT_API_BASE_URL;
    delete process.env.CITYSCOUT_APP_SHARED_SECRET;
    vi.restoreAllMocks();
    vi.useRealTimers();
  });

  it("rejects non-POST requests with a clean JSON error", async () => {
    const { GET } = await loadRouteModule();

    const response = await GET(buildRequest({}, "GET"));
    const payload = await response.json();

    expect(response.status).toBe(405);
    expect(payload).toEqual({
      error: {
        code: "method_not_allowed",
        message: "Only POST is supported for this route.",
        request_id: REQUEST_ID
      }
    });
    expect(response.headers.get("X-Request-Id")).toBe(REQUEST_ID);
  });

  it("rejects invalid payloads before calling the backend", async () => {
    const fetchSpy = vi.spyOn(globalThis, "fetch");
    const { POST } = await loadRouteModule();

    const response = await POST(
      buildRequest({
        destination: "  ",
        prompt: "  ",
        preferences: [],
        saved_places: []
      })
    );
    const payload = await response.json();

    expect(response.status).toBe(400);
    expect(payload.error.code).toBe("validation_error");
    expect(payload.error.message).toMatch(/expected shape/i);
    expect(payload.error.request_id).toBe(REQUEST_ID);
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it("rejects oversized payloads before calling the backend", async () => {
    const fetchSpy = vi.spyOn(globalThis, "fetch");
    const { POST } = await loadRouteModule();

    const response = await POST(
      buildRequest({
        destination: "Paris",
        prompt: "x".repeat(20_000),
        preferences: [],
        saved_places: []
      })
    );
    const payload = await response.json();

    expect(response.status).toBe(413);
    expect(payload.error.code).toBe("payload_too_large");
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it("rejects invalid day_count values", async () => {
    const fetchSpy = vi.spyOn(globalThis, "fetch");
    const { POST } = await loadRouteModule();

    const response = await POST(
      buildRequest({
        destination: "Paris",
        prompt: "Plan a relaxed day",
        preferences: [],
        saved_places: [],
        day_count: 30
      })
    );
    const payload = await response.json();

    expect(response.status).toBe(400);
    expect(payload.error.code).toBe("validation_error");
    expect(payload.error.message).toMatch(/day_count/i);
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it("forwards a valid request to the backend with the shared secret kept server-side", async () => {
    const fetchSpy = vi.spyOn(globalThis, "fetch").mockResolvedValue(
      new Response(
        JSON.stringify({
          destination: "Paris",
          title: "Paris by foot",
          summary: "A calm day plan.",
          stops: [],
          request_id: BACKEND_REQUEST_ID
        }),
        {
          status: 200,
          headers: {
            "content-type": "application/json",
            "X-Request-Id": BACKEND_REQUEST_ID
          }
        }
      )
    );

    const { POST } = await loadRouteModule();
    const response = await POST(
      buildRequest({
        destination: "  Paris  ",
        prompt: "  Plan a relaxed day  ",
        preferences: [" Relaxed ", "", null, " Cafes "],
        saved_places: [" Louvre Museum ", " ", "Cafe de Flore", 42]
      })
    );
    const payload = await response.json();

    expect(fetchSpy).toHaveBeenCalledTimes(1);
    const [url, init] = fetchSpy.mock.calls[0];
    expect(String(url)).toBe(`${API_BASE_URL}/plan-itinerary`);
    expect(init?.method).toBe("POST");
    expect(init?.headers).toMatchObject({
      Accept: "application/json",
      "Content-Type": "application/json",
      "X-CityScout-App-Secret": APP_SHARED_SECRET,
      "X-Request-Id": REQUEST_ID
    });
    expect(JSON.parse(String(init?.body))).toEqual({
      destination: "Paris",
      prompt: "Plan a relaxed day",
      preferences: ["Relaxed", "Cafes"],
      saved_places: ["Louvre Museum", "Cafe de Flore"]
    });
    expect(response.status).toBe(200);
    expect(payload.request_id).toBe(BACKEND_REQUEST_ID);
    expect(JSON.stringify(payload)).not.toContain(APP_SHARED_SECRET);
    expect(response.headers.get("X-CityScout-App-Secret")).toBeNull();
    expect(response.headers.get("X-Request-Id")).toBe(BACKEND_REQUEST_ID);
  });

  it("returns backend non-2xx errors as structured JSON", async () => {
    vi.spyOn(globalThis, "fetch").mockResolvedValue(
      Response.json(
        {
          error: {
            code: "backend_error",
            message: "Upstream unavailable",
            request_id: BACKEND_REQUEST_ID,
            details: { source: "openai" }
          }
        },
        {
          status: 503,
          headers: {
            "X-Request-Id": BACKEND_REQUEST_ID
          }
        }
      )
    );

    const { POST } = await loadRouteModule();
    const response = await POST(
      buildRequest({
        destination: "Paris",
        prompt: "Plan a relaxed day",
        preferences: [],
        saved_places: []
      })
    );
    const payload = await response.json();

    expect(response.status).toBe(503);
    expect(payload).toEqual({
      error: {
        code: "backend_error",
        message: "Upstream unavailable",
        request_id: BACKEND_REQUEST_ID,
        details: { source: "openai" }
      }
    });
    expect(response.headers.get("X-Request-Id")).toBe(BACKEND_REQUEST_ID);
  });

  it("does not expose raw HTML when upstream returns an HTML error page", async () => {
    vi.spyOn(globalThis, "fetch").mockResolvedValue(
      new Response("<html><body><h1>Service Unavailable</h1></body></html>", {
        status: 503,
        headers: {
          "content-type": "text/html",
          "X-Request-Id": BACKEND_REQUEST_ID
        }
      })
    );

    const { POST } = await loadRouteModule();
    const response = await POST(
      buildRequest({
        destination: "Paris",
        prompt: "Plan a relaxed day",
        preferences: [],
        saved_places: []
      })
    );
    const payload = await response.json();

    expect(response.status).toBe(503);
    expect(payload).toEqual({
      error: {
        code: "internal_error",
        message: "Request failed with status 503.",
        request_id: BACKEND_REQUEST_ID
      }
    });
  });

  it("rate limits repeated requests from the same client", async () => {
    const fetchSpy = vi.spyOn(globalThis, "fetch").mockImplementation(() =>
      Promise.resolve(
        new Response(
          JSON.stringify({
            destination: "Paris",
            morning: { title: "Morning", activities: [] },
            afternoon: { title: "Afternoon", activities: [] },
            evening: { title: "Evening", activities: [] },
            notes: [],
            request_id: BACKEND_REQUEST_ID
          }),
          {
            status: 200,
            headers: {
              "content-type": "application/json",
              "X-Request-Id": BACKEND_REQUEST_ID
            }
          }
        )
      )
    );

    const { POST } = await loadRouteModule();
    for (let index = 0; index < 10; index++) {
      const response = await POST(
        buildRequest({
          destination: "Paris",
          prompt: "Plan a relaxed day",
          preferences: [],
          saved_places: []
        })
      );
      expect(response.status).toBe(200);
    }

    const rateLimitedResponse = await POST(
      buildRequest({
        destination: "Paris",
        prompt: "Plan a relaxed day",
        preferences: [],
        saved_places: []
      })
    );
    const payload = await rateLimitedResponse.json();

    expect(rateLimitedResponse.status).toBe(429);
    expect(payload).toEqual({
      error: {
        code: "rate_limited",
        message: "Too many requests. Please retry in about 600 seconds.",
        request_id: REQUEST_ID
      }
    });
    expect(rateLimitedResponse.headers.get("Retry-After")).toBe("600");
    expect(rateLimitedResponse.headers.get("X-Request-Id")).toBe(REQUEST_ID);
    expect(fetchSpy).toHaveBeenCalledTimes(10);
  });

  it("returns a clean timeout error when the backend does not respond in time", async () => {
    vi.useFakeTimers();
    vi.spyOn(globalThis, "fetch").mockImplementation((_input, init) => {
      const signal = init?.signal as AbortSignal | undefined;
      return new Promise<Response>((_resolve, reject) => {
        signal?.addEventListener("abort", () => {
          reject(new DOMException("Request aborted", "AbortError"));
        });
      });
    });

    const { POST } = await loadRouteModule();
    const responsePromise = POST(
      buildRequest({
        destination: "Paris",
        prompt: "Plan a relaxed day",
        preferences: [],
        saved_places: []
      })
    );

    await vi.advanceTimersByTimeAsync(20_000);
    const response = await responsePromise;
    const payload = await response.json();

    expect(response.status).toBe(504);
    expect(payload).toEqual({
      error: {
        code: "upstream_timeout",
        message: "The backend request timed out.",
        request_id: REQUEST_ID
      }
    });
    expect(response.headers.get("X-Request-Id")).toBe(REQUEST_ID);
    vi.useRealTimers();
  });

  it("returns a structured JSON error when the backend URL is unavailable", async () => {
    delete process.env.CITYSCOUT_API_BASE_URL;

    const { POST } = await loadRouteModule();
    const response = await POST(
      buildRequest({
        destination: "Paris",
        prompt: "Plan a relaxed day",
        preferences: [],
        saved_places: []
      })
    );
    const payload = await response.json();

    expect(response.status).toBe(500);
    expect(payload).toEqual({
      error: {
        code: "proxy_misconfigured",
        message: "CITYSCOUT_API_BASE_URL is not configured.",
        request_id: REQUEST_ID
      }
    });
  });

  it("returns a structured JSON error when the shared secret is unavailable", async () => {
    delete process.env.CITYSCOUT_APP_SHARED_SECRET;

    const { POST } = await loadRouteModule();
    const response = await POST(
      buildRequest({
        destination: "Paris",
        prompt: "Plan a relaxed day",
        preferences: [],
        saved_places: []
      })
    );
    const payload = await response.json();

    expect(response.status).toBe(500);
    expect(payload).toEqual({
      error: {
        code: "proxy_misconfigured",
        message: "CITYSCOUT_APP_SHARED_SECRET is not configured.",
        request_id: REQUEST_ID
      }
    });
  });
});
