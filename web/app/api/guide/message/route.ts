import { type NextRequest } from "next/server";
import { enforceWebProxyRateLimit, proxyJsonToBackend } from "@/app/api/_lib/proxy";
import type { GuideMessageRequest } from "@/types/guide";

const MAX_BODY_BYTES = 12 * 1024;
const MAX_DESTINATION_LENGTH = 80;
const MAX_PROMPT_LENGTH = 1000;
const MAX_CONTEXT_ITEMS = 20;

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
      .slice(0, MAX_CONTEXT_ITEMS)
  };
}

export async function POST(request: NextRequest) {
  const requestId = request.headers.get("X-Request-Id") ?? crypto.randomUUID();
  const rateLimitError = enforceWebProxyRateLimit(request, requestId, "/guide/message");
  if (rateLimitError) {
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

  if (normalized.destination.length > MAX_DESTINATION_LENGTH || normalized.message.length > MAX_PROMPT_LENGTH) {
    return Response.json(
      {
        error: {
          code: "validation_error",
          message: "Destination or message exceeds the supported length.",
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
