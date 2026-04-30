import logging

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from app.core.http import MAX_REQUEST_BODY_BYTES, attach_response_security_headers, error_response, get_request_id
from app.core.config import settings
from app.routes.guide import router as guide_router
from app.routes.itinerary import router as itinerary_router


logger = logging.getLogger(__name__)

app = FastAPI(title="CityScout Backend", version="0.1.0")

cors_origins = settings.cors_origins()
if cors_origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=cors_origins,
        allow_credentials=False,
        allow_methods=["GET", "POST", "OPTIONS"],
        allow_headers=["Content-Type", "X-CityScout-App-Secret"],
    )


@app.middleware("http")
async def add_request_context(request: Request, call_next):
    request_id = get_request_id(request)

    content_length = request.headers.get("content-length")
    if content_length is not None:
        try:
            if int(content_length) > MAX_REQUEST_BODY_BYTES:
                return error_response(
                    413,
                    "Request body too large",
                    request_id,
                    code="PAYLOAD_TOO_LARGE",
                )
        except ValueError:
            pass

    response = await call_next(request)
    attach_response_security_headers(response, request_id)
    return response


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
    request_id = get_request_id(request)
    detail = exc.detail if isinstance(exc.detail, str) else "Request failed."
    return error_response(exc.status_code, detail, request_id, details=exc.detail if not isinstance(exc.detail, str) else None)


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
    request_id = get_request_id(request)
    return error_response(
        422,
        "Invalid request body",
        request_id,
        code="VALIDATION_ERROR",
        details=exc.errors(),
    )


@app.exception_handler(Exception)
async def unexpected_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    request_id = get_request_id(request)
    logger.exception("Unexpected server error request_id=%s", request_id)
    return error_response(500, "Internal server error", request_id, code="INTERNAL_SERVER_ERROR")


@app.get("/health")
def health(request: Request) -> dict[str, str]:
    return {"status": "ok", "request_id": get_request_id(request)}


app.include_router(itinerary_router)
app.include_router(guide_router)
