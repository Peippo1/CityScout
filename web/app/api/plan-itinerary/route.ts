import { type NextRequest } from "next/server";
import { proxyJsonToBackend } from "@/app/api/_lib/proxy";
import type { PlanItineraryRequest } from "@/types/itinerary";

function methodNotAllowedResponse(requestId: string) {
  return Response.json(
    {
      error: {
        code: "method_not_allowed",
        message: "Only POST is supported for this route.",
        request_id: requestId
      }
    },
    {
      status: 405,
      headers: {
        "X-Request-Id": requestId
      }
    }
  );
}

function isPlanItineraryRequest(value: unknown): value is PlanItineraryRequest {
  if (!isRecord(value)) {
    return false;
  }

  return (
    typeof value.destination === "string" &&
    typeof value.prompt === "string" &&
    Array.isArray(value.preferences) &&
    Array.isArray(value.saved_places)
  );
}

function normalizeRequest(value: unknown): PlanItineraryRequest | null {
  if (!isPlanItineraryRequest(value)) {
    return null;
  }

  return {
    destination: value.destination.trim(),
    prompt: value.prompt.trim(),
    preferences: value.preferences
      .filter((item): item is string => typeof item === "string")
      .map((item) => item.trim())
      .filter(Boolean)
      .slice(0, 10),
    saved_places: value.saved_places
      .filter((item): item is string => typeof item === "string")
      .map((item) => item.trim())
      .filter(Boolean)
      .slice(0, 25)
  };
}

export async function POST(request: NextRequest) {
  const requestId = request.headers.get("X-Request-Id") ?? crypto.randomUUID();
  let parsedBody: unknown;
  try {
    parsedBody = await request.json();
  } catch {
    return Response.json(
      {
        error: {
          code: "invalid_json",
          message: "The request body must be valid JSON.",
          request_id: requestId
        }
      },
      {
        status: 400,
        headers: {
          "X-Request-Id": requestId
        }
      }
    );
  }

  const normalized = normalizeRequest(parsedBody);
  if (!normalized || normalized.destination.length === 0 || normalized.prompt.length === 0) {
    return Response.json(
      {
        error: {
          code: "validation_error",
          message: "Destination, prompt, preferences, and saved_places must be provided in the expected shape.",
          request_id: requestId
        }
      },
      {
        status: 422,
        headers: {
          "X-Request-Id": requestId
        }
      }
    );
  }

  if (normalized.destination.length > 80 || normalized.prompt.length > 1000) {
    return Response.json(
      {
        error: {
          code: "validation_error",
          message: "Destination or prompt exceeds the supported length.",
          request_id: requestId
        }
      },
      {
        status: 422,
        headers: {
          "X-Request-Id": requestId
        }
      }
    );
  }

  return proxyJsonToBackend({
    request,
    backendPath: "/plan-itinerary",
    method: "POST",
    requestBody: normalized,
    requestId
  });
}

export async function GET(request: NextRequest) {
  const requestId = request.headers.get("X-Request-Id") ?? crypto.randomUUID();
  return methodNotAllowedResponse(requestId);
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
