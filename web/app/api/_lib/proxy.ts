import type { NextRequest } from "next/server";

const BACKEND_BASE_URL = process.env.CITYSCOUT_API_BASE_URL?.trim();
const BACKEND_SHARED_SECRET = process.env.CITYSCOUT_APP_SHARED_SECRET?.trim();
const REQUEST_ID_HEADER = "X-Request-Id";
const APP_SECRET_HEADER = "X-CityScout-App-Secret";
const DEFAULT_TIMEOUT_MS = 20_000;

export interface ProxyErrorBody {
  error: {
    code: string;
    message: string;
    request_id?: string;
    details?: unknown;
  };
}

export interface RouteContext {
  request: NextRequest;
  backendPath: string;
  method: "POST";
  requestBody: unknown;
  requestId?: string;
}

export async function proxyJsonToBackend({ request, backendPath, method, requestBody, requestId }: RouteContext) {
  const incomingRequestId = requestId ?? request.headers.get(REQUEST_ID_HEADER) ?? crypto.randomUUID();
  const configError = validateConfiguration(incomingRequestId);
  if (configError) {
    return Response.json(configError.body, {
      status: configError.status,
      headers: configError.headers
    });
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(new DOMException("Proxy timeout", "TimeoutError")), DEFAULT_TIMEOUT_MS);

  try {
    const response = await fetch(resolveBackendUrl(backendPath), {
      method,
      signal: controller.signal,
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        [APP_SECRET_HEADER]: BACKEND_SHARED_SECRET as string,
        [REQUEST_ID_HEADER]: incomingRequestId
      },
      body: JSON.stringify(requestBody)
    });

    const { payload, requestId } = await readResponsePayload(response);
    const mergedRequestId = requestId ?? incomingRequestId;

    if (!response.ok) {
      return Response.json(
        {
          error: normalizeErrorBody(response.status, payload, mergedRequestId)
        },
        {
          status: response.status,
          headers: responseHeaders(mergedRequestId)
        }
      );
    }

    if (payload === null) {
      return Response.json(
        {
          error: {
            code: "empty_response",
            message: "The backend returned an empty response.",
            request_id: mergedRequestId
          }
        },
        {
          status: 502,
          headers: responseHeaders(mergedRequestId)
        }
      );
    }

    const normalized = normalizeSuccessBody(payload, mergedRequestId);
    return Response.json(normalized, {
      status: 200,
      headers: responseHeaders(mergedRequestId)
    });
  } catch (error) {
    const requestId = incomingRequestId;

    if (isAbortError(error)) {
      return Response.json(
        {
          error: {
            code: "upstream_timeout",
            message: "The backend request timed out.",
            request_id: requestId
          }
        },
        {
          status: 504,
          headers: responseHeaders(requestId)
        }
      );
    }

    return Response.json(
      {
        error: {
          code: "proxy_error",
          message: "The web proxy could not reach the backend.",
          request_id: requestId
        }
      },
      {
        status: 502,
        headers: responseHeaders(requestId)
      }
    );
  } finally {
    clearTimeout(timeout);
  }
}

function validateConfiguration(requestId: string) {
  if (!BACKEND_BASE_URL) {
    return {
      status: 500,
      headers: responseHeaders(requestId),
      body: {
        error: {
          code: "proxy_misconfigured",
          message: "CITYSCOUT_API_BASE_URL is not configured.",
          request_id: requestId
        }
      } satisfies ProxyErrorBody
    };
  }

  if (!BACKEND_SHARED_SECRET) {
    return {
      status: 500,
      headers: responseHeaders(requestId),
      body: {
        error: {
          code: "proxy_misconfigured",
          message: "CITYSCOUT_APP_SHARED_SECRET is not configured.",
          request_id: requestId
        }
      } satisfies ProxyErrorBody
    };
  }

  return null;
}

function resolveBackendUrl(path: string) {
  const normalizedBase = BACKEND_BASE_URL?.replace(/\/+$/, "") ?? "";
  const normalizedPath = path.startsWith("/") ? path : `/${path}`;
  return `${normalizedBase}${normalizedPath}`;
}

async function readResponsePayload(response: Response) {
  const requestId = response.headers.get(REQUEST_ID_HEADER) ?? undefined;
  const contentType = response.headers.get("content-type") ?? "";
  if (contentType.includes("application/json")) {
    try {
      return {
        payload: await response.json(),
        requestId
      };
    } catch {
      return {
        payload: null,
        requestId
      };
    }
  }

  try {
    const text = await response.text();
    return {
      payload: text ? text : null,
      requestId
    };
  } catch {
    return {
      payload: null,
      requestId
    };
  }
}

function normalizeErrorBody(status: number, payload: unknown, requestId: string) {
  if (typeof payload === "string" && payload.trim()) {
    return {
      code: codeFromStatus(status),
      message: payload.trim(),
      request_id: requestId
    };
  }

  if (isRecord(payload) && isRecord(payload.error)) {
    return {
      code: asString(payload.error.code, codeFromStatus(status)),
      message: asString(payload.error.message, `Request failed with status ${status}.`),
      request_id: asOptionalString(payload.error.request_id) ?? asOptionalString(payload.error.requestId) ?? requestId,
      details: payload.error.details
    };
  }

  if (isRecord(payload) && typeof payload.detail === "string") {
    return {
      code: codeFromStatus(status),
      message: payload.detail,
      request_id: asOptionalString(payload.request_id) ?? asOptionalString(payload.requestId) ?? requestId
    };
  }

  if (isRecord(payload) && typeof payload.detail === "object" && payload.detail !== null) {
    return {
      code: codeFromStatus(status),
      message: "Request failed.",
      request_id: asOptionalString(payload.request_id) ?? asOptionalString(payload.requestId) ?? requestId,
      details: payload.detail
    };
  }

  return {
    code: codeFromStatus(status),
    message: `Request failed with status ${status}.`,
    request_id: isRecord(payload)
      ? asOptionalString(payload.request_id) ?? asOptionalString(payload.requestId) ?? requestId
      : requestId,
    details: payload
  };
}

function normalizeSuccessBody(payload: unknown, requestId: string) {
  if (!isRecord(payload)) {
    return {
      data: payload,
      request_id: requestId
    };
  }

  const normalized = { ...payload } as Record<string, unknown>;
  if (normalized.request_id === undefined && normalized.requestId === undefined) {
    normalized.request_id = requestId;
  }
  if (normalized.request_id === undefined && normalized.requestId !== undefined) {
    normalized.request_id = asOptionalString(normalized.requestId) ?? requestId;
  }
  return normalized;
}

function responseHeaders(requestId?: string) {
  const headers = new Headers();
  headers.set("Cache-Control", "no-store");
  headers.set("X-Content-Type-Options", "nosniff");
  if (requestId) {
    headers.set(REQUEST_ID_HEADER, requestId);
  }
  return headers;
}

function codeFromStatus(status: number) {
  switch (status) {
    case 400:
      return "invalid_request";
    case 401:
      return "unauthorized";
    case 403:
      return "forbidden";
    case 404:
      return "not_found";
    case 409:
      return "conflict";
    case 422:
      return "validation_error";
    case 429:
      return "rate_limited";
    default:
      return status >= 500 ? "internal_error" : `http_${status}`;
  }
}

function isAbortError(error: unknown) {
  return error instanceof DOMException && (error.name === "AbortError" || error.name === "TimeoutError");
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function asString(value: unknown, fallback: string) {
  return typeof value === "string" && value.trim() ? value : fallback;
}

function asOptionalString(value: unknown) {
  return typeof value === "string" && value.trim() ? value : undefined;
}
