import { type NextRequest } from "next/server";
import { enforceWebProxyRateLimit, proxyJsonToBackend } from "@/app/api/_lib/proxy";
import { log, hashIp, startTimer } from "@/lib/logger";
import type { PlanItineraryRequest } from "@/types/itinerary";

const MAX_BODY_BYTES = 16 * 1024;
const MAX_DESTINATION_LENGTH = 80;
const MAX_PROMPT_LENGTH = 1000;
const MAX_INTERESTS = 10;
const MAX_INTEREST_LENGTH = 60;
const MAX_SAVED_PLACES = 25;
const MAX_DAY_COUNT = 14;

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

  const rawDayCount = value.day_count;
  const dayCount =
    typeof rawDayCount === "number" && Number.isInteger(rawDayCount) ? rawDayCount : undefined;

  return {
    destination: value.destination.trim(),
    prompt: value.prompt.trim(),
    preferences: value.preferences
      .filter((item): item is string => typeof item === "string")
      .map((item) => item.trim())
      .filter(Boolean),
    saved_places: value.saved_places
      .filter((item): item is string => typeof item === "string")
      .map((item) => item.trim())
      .filter(Boolean),
    ...(dayCount !== undefined ? { day_count: dayCount } : {})
  };
}

export async function POST(request: NextRequest) {
  const elapsed = startTimer();
  const requestId = request.headers.get("X-Request-Id") ?? crypto.randomUUID();
  const clientIp = request.headers.get("x-forwarded-for")?.split(",")[0]?.trim()
    ?? request.headers.get("x-real-ip")?.trim()
    ?? "unknown";

  const rateLimitError = enforceWebProxyRateLimit(request, requestId, "/plan-itinerary");
  if (rateLimitError) {
    log({
      level: "warn",
      route: "/api/plan-itinerary",
      event: "rate_limited",
      requestId,
      status: 429,
      clientHash: await hashIp(clientIp),
      durationMs: elapsed()
    });
    return rateLimitError;
  }

  const contentLength = Number(request.headers.get("content-length") ?? "0");
  if (Number.isFinite(contentLength) && contentLength > MAX_BODY_BYTES) {
    return Response.json(
      {
        error: {
          code: "payload_too_large",
          message: "Request body is too large. Reduce payload size and retry.",
          request_id: requestId
        }
      },
      {
        status: 413,
        headers: {
          "X-Request-Id": requestId
        }
      }
    );
  }

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
        status: 400,
        headers: {
          "X-Request-Id": requestId
        }
      }
    );
  }

  const serializedLength = new TextEncoder().encode(JSON.stringify(normalized)).length;
  if (serializedLength > MAX_BODY_BYTES) {
    return Response.json(
      {
        error: {
          code: "payload_too_large",
          message: "Request body is too large. Reduce payload size and retry.",
          request_id: requestId
        }
      },
      {
        status: 413,
        headers: {
          "X-Request-Id": requestId
        }
      }
    );
  }

  if (normalized.destination.length > MAX_DESTINATION_LENGTH || normalized.prompt.length > MAX_PROMPT_LENGTH) {
    return Response.json(
      {
        error: {
          code: "validation_error",
          message: "Destination or prompt exceeds the supported length.",
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

  if (normalized.day_count !== undefined && (normalized.day_count < 1 || normalized.day_count > MAX_DAY_COUNT)) {
    return Response.json(
      {
        error: {
          code: "validation_error",
          message: `day_count must be between 1 and ${MAX_DAY_COUNT}.`,
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

  if (normalized.preferences.length > MAX_INTERESTS) {
    return Response.json(
      {
        error: {
          code: "validation_error",
          message: `preferences must contain at most ${MAX_INTERESTS} items.`,
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

  if (normalized.preferences.some((item) => item.length > MAX_INTEREST_LENGTH)) {
    return Response.json(
      {
        error: {
          code: "validation_error",
          message: `Each preference must be at most ${MAX_INTEREST_LENGTH} characters.`,
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

  if (normalized.saved_places.length > MAX_SAVED_PLACES) {
    return Response.json(
      {
        error: {
          code: "validation_error",
          message: `saved_places must contain at most ${MAX_SAVED_PLACES} items.`,
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

  const response = await proxyJsonToBackend({
    request,
    backendPath: "/plan-itinerary",
    method: "POST",
    requestBody: normalized,
    requestId
  });

  log({
    level: response.ok ? "info" : "warn",
    route: "/api/plan-itinerary",
    event: response.ok ? "generation_complete" : "upstream_error",
    requestId,
    status: response.status,
    destination: normalized.destination,
    durationMs: elapsed()
  });

  return response;
}

export async function GET(request: NextRequest) {
  const requestId = request.headers.get("X-Request-Id") ?? crypto.randomUUID();
  return methodNotAllowedResponse(requestId);
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
