// @vitest-environment node

import { NextRequest } from "next/server";
import { afterEach, describe, expect, it, vi } from "vitest";
import { POST } from "@/app/api/plan-itinerary/route";
import { proxyJsonToBackend } from "@/app/api/_lib/proxy";

vi.mock("@/app/api/_lib/proxy", () => ({
  proxyJsonToBackend: vi.fn(async ({ requestBody, requestId }) =>
    Response.json(
      {
        ok: true,
        requestBody,
        request_id: requestId
      },
      {
        status: 200,
        headers: {
          "X-Request-Id": requestId
        }
      }
    )
  )
}));

describe("plan-itinerary route", () => {
  afterEach(() => {
    vi.clearAllMocks();
  });

  it("normalizes the request payload before proxying to the backend", async () => {
    const request = new NextRequest("http://localhost/api/plan-itinerary", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "X-Request-Id": "request-123"
      },
      body: JSON.stringify({
        destination: "  Paris  ",
        prompt: "  Plan a relaxed day  ",
        preferences: [" Relaxed ", "", null, " Cafes "],
        saved_places: [" Louvre Museum ", " ", "Cafe de Flore", 42]
      })
    });

    const response = await POST(request);
    const payload = await response.json();

    expect(response.status).toBe(200);
    expect(payload.request_id).toBe("request-123");
    expect(proxyJsonToBackend).toHaveBeenCalledTimes(1);
    expect(proxyJsonToBackend).toHaveBeenCalledWith(
      expect.objectContaining({
        backendPath: "/plan-itinerary",
        method: "POST",
        requestId: "request-123",
        requestBody: {
          destination: "Paris",
          prompt: "Plan a relaxed day",
          preferences: ["Relaxed", "Cafes"],
          saved_places: ["Louvre Museum", "Cafe de Flore"]
        }
      })
    );
  });
});
