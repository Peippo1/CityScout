import { type NextRequest } from "next/server";
import { proxyJsonToBackend } from "@/app/api/_lib/proxy";
import type { GuideMessageRequest } from "@/types/guide";

function isGuideMessageRequest(value: unknown): value is GuideMessageRequest {
  if (!isRecord(value)) {
    return false;
  }

  return typeof value.destination === "string" && typeof value.message === "string" && Array.isArray(value.context);
}

function normalizeRequest(value: unknown): GuideMessageRequest | null {
  if (!isGuideMessageRequest(value)) {
    return null;
  }

  return {
    destination: value.destination.trim(),
    message: value.message.trim(),
    context: value.context
      .filter((item): item is string => typeof item === "string")
      .map((item) => item.trim())
      .filter(Boolean)
      .slice(0, 20)
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
  if (!normalized || normalized.destination.length === 0 || normalized.message.length === 0) {
    return Response.json(
      {
        error: {
          code: "validation_error",
          message: "Destination, message, and context must be provided in the expected shape.",
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

  if (normalized.destination.length > 80 || normalized.message.length > 1000) {
    return Response.json(
      {
        error: {
          code: "validation_error",
          message: "Destination or message exceeds the supported length.",
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
    backendPath: "/guide/message",
    method: "POST",
    requestBody: normalized,
    requestId
  });
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
