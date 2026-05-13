# Skill: FastAPI Integration

## Purpose
Guide correct patterns for working with the CityScout FastAPI backend — adding routes, writing services, maintaining the API contract, and integrating with OpenAI.

## When to use
- Adding or modifying a route in `backend/app/routes/`.
- Adding or modifying a service in `backend/app/services/`.
- Changing the request or response schema in `backend/app/schemas/`.
- Debugging a backend error or OpenAI integration issue.

---

## Key rules

### Route handlers
- Routes live in `backend/app/routes/`. One router per feature area.
- Register routers in `backend/app/main.py` via `app.include_router(...)`.
- Validate request bodies using Pydantic models from `backend/app/schemas/`.
- Use FastAPI's dependency injection for shared concerns (auth, rate limiting).
- Return structured Pydantic response models — not raw dicts.

### Authentication
- Every non-health endpoint validates `X-CityScout-App-Secret` against `APP_SHARED_SECRET`.
- If the header is missing or wrong, return 401.
- The health endpoint (`GET /health`) is intentionally unauthenticated. Keep it that way — it must not leak internal state.

### Error envelope
All non-2xx responses must use the shared `error_response()` helper from `app/core/http.py`:
```python
return error_response(422, "Invalid request body", request_id, code="VALIDATION_ERROR", details=exc.errors())
```

The resulting shape:
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request body",
    "request_id": "...",
    "details": [...]
  }
}
```

This is the shape that `web/lib/api.ts` parses. Breaking it breaks client error handling.

### Request ID
- Every request carries a `request_id` (from `X-Request-Id` header or generated in middleware).
- Pass it to `error_response()` and include it in success responses.
- Log the `request_id` on every error: `logger.exception("...", request_id)`.

### OpenAI integration
- OpenAI calls live in `backend/app/services/` — never in routes directly.
- Set explicit `max_tokens` on every completion call.
- Catch `openai.APIError` and map it to a 503 `upstream_unavailable` response.
- Catch `openai.APITimeoutError` and map it to a 504 `upstream_timeout` response.
- Never log the full prompt in production — it may contain user input.

### Rate limiting
- The backend has an in-memory rate limiter (currently enforced per-IP).
- Do not remove or weaken it without review.
- The rate-limit response must use status 429 and code `rate_limited`.

### CORS
- `APP_ALLOWED_ORIGIN(S)` controls the allowed frontend origins.
- In development, this is typically `http://localhost:3000`.
- In production, it must be the deployed web app domain — not `*`.

---

## Pydantic schema patterns

```python
from pydantic import BaseModel, Field, field_validator

class PlanItineraryRequest(BaseModel):
    destination: str = Field(..., min_length=1, max_length=80)
    prompt: str = Field(..., min_length=1, max_length=1000)
    preferences: list[str] = Field(default_factory=list, max_length=10)
    saved_places: list[str] = Field(default_factory=list, max_length=25)

    @field_validator("destination", "prompt", mode="before")
    @classmethod
    def strip_whitespace(cls, v: str) -> str:
        return v.strip()
```

### Response schema evolution
- Add new fields as optional with defaults — never remove existing fields without a migration window.
- The iOS client may not yet consume new fields; that is fine.
- Legacy fields (`morning`, `afternoon`, `evening`, `notes`) must remain until iOS migration is confirmed.

---

## Testing patterns

```python
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock

def test_valid_request(client: TestClient, valid_secret: str):
    with patch("app.services.itinerary.generate_itinerary") as mock_gen:
        mock_gen.return_value = mock_itinerary_response()
        response = client.post(
            "/plan-itinerary",
            json={"destination": "Paris", "prompt": "A relaxed day", "preferences": [], "saved_places": []},
            headers={"X-CityScout-App-Secret": valid_secret},
        )
    assert response.status_code == 200
    data = response.json()
    assert data["destination"] == "Paris"
    assert "request_id" in data
```

Cover:
- Happy path with expected response shape.
- Missing/invalid secret → 401.
- Missing required fields → 422.
- Rate limit → 429.
- OpenAI failure → 503.
- Security: `test_security.py` covers header injection and oversized payloads.

---

## Anti-patterns

- Calling OpenAI directly from a route handler.
- Hardcoding the shared secret in tests (use the fixture from `conftest.py`).
- Returning a plain `dict` instead of a Pydantic model from a route — this bypasses response validation.
- Catching `Exception` broadly and returning 200 (hide the real error).
- Adding new optional parameters that silently change the OpenAI prompt without updating the contract doc.

---

## Definition of success
- `python -m pytest` passes, including new route tests.
- `bandit -r app -x tests` reports no high-severity findings.
- New routes follow the auth, error envelope, and rate-limit patterns.
- Legacy response fields remain present.
- `docs/API_CONTRACT.md` reflects any contract changes.
