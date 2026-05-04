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
    for (let index = 0; index < 20; index++) {
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
        message: "Too many requests. Please try again shortly.",
        request_id: REQUEST_ID
      }
    });
    expect(rateLimitedResponse.headers.get("X-Request-Id")).toBe(REQUEST_ID);
  });
});
