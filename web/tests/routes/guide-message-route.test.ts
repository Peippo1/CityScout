// @vitest-environment node

import { NextRequest } from "next/server";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const API_BASE_URL = "http://backend.test";
const APP_SHARED_SECRET = "server-only-secret";
const REQUEST_ID = "request-123";
const BACKEND_REQUEST_ID = "backend-456";

async function loadRouteModule() {
  vi.resetModules();
  return import("@/app/api/guide/message/route");
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

  return new NextRequest("http://localhost/api/guide/message", init);
}

describe("POST /api/guide/message", () => {
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

  it("forwards a valid request to the backend with the shared secret kept server-side", async () => {
    const fetchSpy = vi.spyOn(globalThis, "fetch").mockResolvedValue(
      new Response(
        JSON.stringify({
          destination: "Paris",
          reply: "Walk the Marais then stop for dinner.",
          suggested_prompts: ["What should I know about this city?"],
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
        message: "  Give me a short walking tour  ",
        context: ["  nearby neighborhoods  ", "", null]
      })
    );
    const payload = await response.json();

    expect(fetchSpy).toHaveBeenCalledTimes(1);
    const [url, init] = fetchSpy.mock.calls[0];
    expect(String(url)).toBe(`${API_BASE_URL}/guide/message`);
    expect(init?.method).toBe("POST");
    expect(init?.headers).toMatchObject({
      Accept: "application/json",
      "Content-Type": "application/json",
      "X-CityScout-App-Secret": APP_SHARED_SECRET,
      "X-Request-Id": REQUEST_ID
    });
    expect(JSON.parse(String(init?.body))).toEqual({
      destination: "Paris",
      message: "Give me a short walking tour",
      context: ["nearby neighborhoods"]
    });
    expect(response.status).toBe(200);
    expect(payload.request_id).toBe(BACKEND_REQUEST_ID);
    expect(response.headers.get("X-Request-Id")).toBe(BACKEND_REQUEST_ID);
  });

  it("rejects invalid payloads before calling the backend", async () => {
    const fetchSpy = vi.spyOn(globalThis, "fetch");
    const { POST } = await loadRouteModule();

    const response = await POST(
      buildRequest({
        destination: " ",
        message: " ",
        context: []
      })
    );
    const payload = await response.json();

    expect(response.status).toBe(400);
    expect(payload.error.code).toBe("validation_error");
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it("rejects oversized payloads before calling the backend", async () => {
    const fetchSpy = vi.spyOn(globalThis, "fetch");
    const { POST } = await loadRouteModule();

    const response = await POST(
      buildRequest({
        destination: "Paris",
        message: "x".repeat(20_000),
        context: []
      })
    );
    const payload = await response.json();

    expect(response.status).toBe(413);
    expect(payload.error.code).toBe("payload_too_large");
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it("rate limits repeated requests from the same client", async () => {
    vi.spyOn(globalThis, "fetch").mockImplementation(() =>
      Promise.resolve(
        new Response(
          JSON.stringify({
            destination: "Paris",
            reply: "Walk the Marais then stop for dinner.",
            suggested_prompts: ["What should I know about this city?"],
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
    for (let index = 0; index < 30; index++) {
      const response = await POST(
        buildRequest({
          destination: "Paris",
          message: "Give me a short walking tour",
          context: []
        })
      );
      expect(response.status).toBe(200);
    }

    const rateLimitedResponse = await POST(
      buildRequest({
        destination: "Paris",
        message: "Give me a short walking tour",
        context: []
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
        message: "Give me a short walking tour",
        context: []
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
        message: "Give me a short walking tour",
        context: []
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
});
