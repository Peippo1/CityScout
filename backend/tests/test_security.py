from __future__ import annotations

from types import SimpleNamespace

from app.core import security
from app.core.config import Settings
from app.services import guide_service


class _FakeGuideCompletion:
    def __init__(self, content: str) -> None:
        self.choices = [SimpleNamespace(message=SimpleNamespace(content=content))]


class _FakeGuideCompletions:
    def __init__(self, content: str) -> None:
        self._content = content

    def create(self, *args, **kwargs):
        return _FakeGuideCompletion(self._content)


class _FakeGuideChat:
    def __init__(self, content: str) -> None:
        self.completions = _FakeGuideCompletions(content)


class _FakeGuideClient:
    def __init__(self, *args, **kwargs) -> None:
        self.chat = _FakeGuideChat("Test reply")


def test_shared_secret_validation_uses_timing_safe_comparison(client, monkeypatch) -> None:
    calls: list[tuple[str, str]] = []

    def fake_compare_digest(supplied: str, expected: str) -> bool:
        calls.append((supplied, expected))
        return True

    monkeypatch.setattr(security.hmac, "compare_digest", fake_compare_digest)
    monkeypatch.setattr(security.settings, "require_app_shared_secret", lambda: "expected-secret")
    monkeypatch.setattr(guide_service.settings, "require_openai_api_key", lambda: "test-key")
    monkeypatch.setattr(guide_service, "OpenAI", _FakeGuideClient)

    response = client.post(
        "/guide/message",
        json={
            "destination": "Paris",
            "message": "What should I know?",
            "context": [],
        },
        headers={"X-CityScout-App-Secret": "supplied-secret"},
    )

    assert response.status_code == 200
    assert calls == [("supplied-secret", "expected-secret")]


def test_cors_origins_are_empty_in_production_without_configuration(monkeypatch) -> None:
    monkeypatch.setenv("APP_ENV", "production")
    monkeypatch.delenv("APP_ALLOWED_ORIGIN", raising=False)
    monkeypatch.delenv("APP_ALLOWED_ORIGINS", raising=False)

    assert Settings().cors_origins() == []


def test_cors_origins_expand_from_environment(monkeypatch) -> None:
    monkeypatch.setenv("APP_ENV", "production")
    monkeypatch.setenv("APP_ALLOWED_ORIGIN", "https://app.example.com")
    monkeypatch.setenv("APP_ALLOWED_ORIGINS", "https://foo.example.com, https://bar.example.com")

    assert Settings().cors_origins() == [
        "https://app.example.com",
        "https://foo.example.com",
        "https://bar.example.com",
    ]


def test_oversized_request_body_is_rejected_with_structured_error(client, auth_headers) -> None:
    response = client.post(
        "/plan-itinerary",
        json={
            "destination": "Paris",
            "prompt": "x" * (33 * 1024),
            "preferences": [],
            "saved_places": [],
        },
        headers=auth_headers,
    )

    assert response.status_code == 413
    payload = response.json()
    assert payload["error"]["code"] == "PAYLOAD_TOO_LARGE"
    assert payload["error"]["message"] == "Request body too large"
    assert isinstance(payload["request_id"], str)
    assert response.headers["X-Request-Id"] == payload["request_id"]


def test_successful_responses_include_security_headers_and_request_id(client) -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.headers["X-Content-Type-Options"] == "nosniff"
    assert response.headers["X-Frame-Options"] == "DENY"
    assert response.headers["Referrer-Policy"] == "no-referrer"
    assert response.headers["Permissions-Policy"] == "camera=(), geolocation=(), microphone=()"
    assert response.headers["Cache-Control"] == "no-store"
    assert response.headers["X-Request-Id"] == response.json()["request_id"]


def test_logs_do_not_include_shared_secret(client, auth_headers, caplog, monkeypatch) -> None:
    secret = auth_headers["X-CityScout-App-Secret"]
    monkeypatch.setattr(guide_service.settings, "require_openai_api_key", lambda: "test-key")
    monkeypatch.setattr(guide_service, "OpenAI", _FakeGuideClient)

    with caplog.at_level("INFO"):
        response = client.post(
            "/guide/message",
            json={
                "destination": "Paris",
                "message": "What should I know about this city?",
                "context": [],
            },
            headers=auth_headers,
        )

    assert response.status_code == 200
    combined_log_text = "\n".join(record.getMessage() for record in caplog.records)
    assert secret not in combined_log_text
