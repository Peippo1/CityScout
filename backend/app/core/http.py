from __future__ import annotations

from http import HTTPStatus
from uuid import uuid4

from fastapi import Request
from fastapi.responses import JSONResponse


REQUEST_ID_HEADER = "X-Request-Id"
MAX_REQUEST_BODY_BYTES = 32 * 1024

SECURITY_HEADERS = {
    "Cache-Control": "no-store",
    "Permissions-Policy": "camera=(), geolocation=(), microphone=()",
    "Referrer-Policy": "no-referrer",
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
}


def get_request_id(request: Request) -> str:
    request_id = getattr(request.state, "request_id", None)
    if isinstance(request_id, str) and request_id.strip():
        return request_id

    supplied = request.headers.get(REQUEST_ID_HEADER)
    if supplied and supplied.strip():
        request_id = supplied.strip()
    else:
        request_id = uuid4().hex

    request.state.request_id = request_id
    return request_id


def error_code_for_status(status_code: int) -> str:
    mapping = {
        HTTPStatus.UNAUTHORIZED: "UNAUTHORIZED",
        HTTPStatus.REQUEST_ENTITY_TOO_LARGE: "PAYLOAD_TOO_LARGE",
        HTTPStatus.TOO_MANY_REQUESTS: "RATE_LIMITED",
        HTTPStatus.INTERNAL_SERVER_ERROR: "INTERNAL_SERVER_ERROR",
        HTTPStatus.BAD_REQUEST: "BAD_REQUEST",
        HTTPStatus.FORBIDDEN: "FORBIDDEN",
        HTTPStatus.NOT_FOUND: "NOT_FOUND",
        HTTPStatus.UNPROCESSABLE_ENTITY: "VALIDATION_ERROR",
    }
    return mapping.get(HTTPStatus(status_code), f"HTTP_{status_code}")


def error_response(
    status_code: int,
    message: str,
    request_id: str,
    *,
    code: str | None = None,
    details: object | None = None,
) -> JSONResponse:
    payload: dict[str, object] = {
        "error": {
            "code": code or error_code_for_status(status_code),
            "message": message,
        },
        "request_id": request_id,
    }
    if details is not None:
        payload["error"]["details"] = details
    response = JSONResponse(status_code=status_code, content=payload)
    response.headers[REQUEST_ID_HEADER] = request_id
    for header_name, header_value in SECURITY_HEADERS.items():
        response.headers[header_name] = header_value
    return response


def attach_response_security_headers(response, request_id: str) -> None:
    response.headers[REQUEST_ID_HEADER] = request_id
    for header_name, header_value in SECURITY_HEADERS.items():
        response.headers.setdefault(header_name, header_value)
