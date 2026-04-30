from __future__ import annotations

from types import SimpleNamespace

import pytest

from app.core.security import rate_limiter
from app.schemas.guide import GuideMessageResponse
from app.services import guide_service


def _validate_model(model: type, payload: dict) -> object:
    if hasattr(model, "model_validate"):
        return model.model_validate(payload)
    return model.parse_obj(payload)


def _valid_guide_payload() -> dict[str, object]:
    return {
        "destination": "Paris",
        "message": "What should I know about this city?",
        "context": [],
    }


def _fake_openai_success(content: str):
    class FakeCompletions:
        def create(self, *args, **kwargs):
            return SimpleNamespace(
                choices=[SimpleNamespace(message=SimpleNamespace(content=content))]
            )

    class FakeChat:
        def __init__(self):
            self.completions = FakeCompletions()

    class FakeClient:
        def __init__(self, *args, **kwargs):
            self.chat = FakeChat()

    return FakeClient


def _fake_openai_failure(*args, **kwargs):
    class FakeAPITimeoutError(Exception):
        pass

    class FakeCompletions:
        def create(self, *args, **kwargs):
            raise FakeAPITimeoutError("simulated timeout")

    class FakeChat:
        def __init__(self):
            self.completions = FakeCompletions()

    class FakeClient:
        def __init__(self, *args, **kwargs):
            self.chat = FakeChat()

    return FakeAPITimeoutError, FakeClient


def test_guide_message_requires_shared_secret(client) -> None:
    response = client.post("/guide/message", json=_valid_guide_payload())

    assert response.status_code == 401
    payload = response.json()
    assert payload["error"]["code"] == "UNAUTHORIZED"
    assert payload["error"]["message"] == "Unauthorized"
    assert isinstance(payload["request_id"], str)
    assert response.headers["X-Request-Id"] == payload["request_id"]


def test_guide_message_rejects_invalid_shared_secret(client) -> None:
    response = client.post(
        "/guide/message",
        json=_valid_guide_payload(),
        headers={"X-CityScout-App-Secret": "wrong-secret"},
    )

    assert response.status_code == 401
    payload = response.json()
    assert payload["error"]["code"] == "UNAUTHORIZED"
    assert payload["error"]["message"] == "Unauthorized"
    assert isinstance(payload["request_id"], str)
    assert response.headers["X-Request-Id"] == payload["request_id"]


def test_guide_message_accepts_valid_shared_secret_and_returns_valid_response(
    client,
    auth_headers,
    monkeypatch,
) -> None:
    fake_reply = "Start in the historic center, take a short walk, then eat where locals actually queue."
    monkeypatch.setattr(guide_service.settings, "require_openai_api_key", lambda: "test-key")
    monkeypatch.setattr(guide_service, "OpenAI", _fake_openai_success(fake_reply))

    response = client.post("/guide/message", json=_valid_guide_payload(), headers=auth_headers)

    assert response.status_code == 200

    payload = response.json()
    validated = _validate_model(GuideMessageResponse, payload)

    assert validated.destination == "Paris"
    assert validated.reply == fake_reply
    assert isinstance(payload["suggested_prompts"], list)
    assert payload["suggested_prompts"]
    assert isinstance(payload["request_id"], str)
    assert response.headers["X-Request-Id"] == payload["request_id"]


@pytest.mark.parametrize(
    "payload",
    [
        {
            "destination": "Paris",
            "message": "   ",
            "context": [],
        },
        {
            "destination": "   ",
            "message": "Any local etiquette tips?",
            "context": [],
        },
    ],
)
def test_guide_message_rejects_invalid_payloads(client, auth_headers, payload) -> None:
    response = client.post("/guide/message", json=payload, headers=auth_headers)

    assert response.status_code == 422
    body = response.json()
    assert body["error"]["code"] == "VALIDATION_ERROR"
    assert body["error"]["message"] == "Invalid request body"
    assert isinstance(body["error"]["details"], list)
    assert isinstance(body["request_id"], str)


def test_guide_message_rate_limits_after_threshold(client, auth_headers, monkeypatch) -> None:
    monkeypatch.setattr(rate_limiter, "max_requests", 1)

    response = client.post("/guide/message", json=_valid_guide_payload(), headers=auth_headers)
    assert response.status_code == 200

    response = client.post("/guide/message", json=_valid_guide_payload(), headers=auth_headers)

    assert response.status_code == 429
    payload = response.json()
    assert payload["error"]["code"] == "RATE_LIMITED"
    assert payload["error"]["message"] == "Rate limit exceeded"
    assert isinstance(payload["request_id"], str)
    assert response.headers["X-Request-Id"] == payload["request_id"]


def test_guide_message_returns_fallback_when_openai_client_fails(
    client,
    auth_headers,
    monkeypatch,
) -> None:
    fake_error, fake_client = _fake_openai_failure()
    monkeypatch.setattr(guide_service, "APITimeoutError", fake_error)
    monkeypatch.setattr(guide_service, "OpenAI", fake_client)
    monkeypatch.setattr(guide_service.settings, "require_openai_api_key", lambda: "test-key")

    response = client.post("/guide/message", json=_valid_guide_payload(), headers=auth_headers)

    assert response.status_code == 200

    payload = response.json()
    validated = _validate_model(GuideMessageResponse, payload)

    assert validated.destination == "Paris"
    assert payload["reply"].startswith("I can still help with Paris.")
    assert payload["suggested_prompts"]
    assert "Paris" in payload["reply"]
    assert isinstance(payload["request_id"], str)
