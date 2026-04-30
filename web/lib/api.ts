import type { GuideMessageRequest, GuideMessageResponse } from "@/types/guide";
import type { PlanItineraryRequest, PlanItineraryResponse } from "@/types/itinerary";

export interface ApiErrorBody {
  code: string;
  message: string;
  request_id?: string;
  details?: unknown;
}

export class ApiError extends Error {
  readonly status: number;
  readonly code: string;
  readonly requestId?: string;
  readonly details?: unknown;
  readonly payload?: unknown;

  constructor(status: number, body: ApiErrorBody, payload?: unknown) {
    super(body.message);
    this.name = "ApiError";
    this.status = status;
    this.code = body.code;
    this.requestId = body.request_id;
    this.details = body.details;
    this.payload = payload;
  }
}
type RequestOptions = {
  signal?: AbortSignal;
  headers?: HeadersInit;
};

const LOCAL_API_PREFIX = "/api";
const REQUEST_ID_HEADER = "X-Request-Id";

function normalizeApiError(status: number, payload: unknown, requestId?: string): ApiErrorBody {
  if (typeof payload === "string" && payload.trim()) {
    return {
      code: codeFromStatus(status),
      message: payload.trim(),
      request_id: requestId
    };
  }

  if (isRecord(payload) && isRecord(payload.error)) {
    return {
      code: asString(payload.error.code, `http_${status}`),
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

async function requestJson<T>(path: string, init: RequestInit = {}, options: RequestOptions = {}): Promise<T> {
  const response = await fetch(resolveLocalUrl(path), {
    ...init,
    signal: options.signal,
    headers: {
      Accept: "application/json",
      ...(init.headers ?? {}),
      ...(options.headers ?? {})
    }
  });

  const rawBody = await readJsonOrText(response);
  const requestId = response.headers.get(REQUEST_ID_HEADER) ?? undefined;

  if (!response.ok) {
    throw new ApiError(response.status, normalizeApiError(response.status, rawBody, requestId), rawBody);
  }

  if (rawBody === null || rawBody === "") {
    throw new ApiError(response.status, {
      code: "empty_response",
      message: "The server returned an empty response."
    });
  }

  if (isRecord(rawBody)) {
    const normalizedBody = { ...rawBody } as Record<string, unknown>;
    if (normalizedBody.request_id === undefined && normalizedBody.requestId === undefined && requestId) {
      normalizedBody.request_id = requestId;
    }
    if (normalizedBody.request_id === undefined && normalizedBody.requestId !== undefined) {
      normalizedBody.request_id = asOptionalString(normalizedBody.requestId) ?? requestId;
    }
    return normalizedBody as T;
  }

  return rawBody as T;
}

async function readJsonOrText(response: Response): Promise<unknown> {
  const contentType = response.headers.get("content-type") ?? "";
  if (contentType.includes("application/json")) {
    try {
      return await response.json();
    } catch {
      return null;
    }
  }

  try {
    const text = await response.text();
    return text || null;
  } catch {
    return null;
  }
}

function resolveLocalUrl(path: string) {
  const normalizedPath = path.startsWith("/") ? path : `/${path}`;
  return `${LOCAL_API_PREFIX}${normalizedPath}`;
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

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function asString(value: unknown, fallback: string) {
  return typeof value === "string" && value.trim() ? value : fallback;
}

function asOptionalString(value: unknown) {
  return typeof value === "string" && value.trim() ? value : undefined;
}

export async function planItinerary(
  request: PlanItineraryRequest,
  options: RequestOptions = {}
): Promise<PlanItineraryResponse> {
  return requestJson<PlanItineraryResponse>(
    "/api/plan-itinerary",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify(request)
    },
    options
  );
}

export async function sendGuideMessage(
  request: GuideMessageRequest,
  options: RequestOptions = {}
): Promise<GuideMessageResponse> {
  return requestJson<GuideMessageResponse>(
    "/api/guide/message",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify(request)
    },
    options
  );
}
