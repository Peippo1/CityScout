from __future__ import annotations

import json
from types import SimpleNamespace

import pytest

from app.core.security import rate_limiter
from app.schemas.itinerary import ItineraryResponse
from app.services import itinerary_service


def _validate_model(model: type, payload: dict) -> object:
    if hasattr(model, "model_validate"):
        return model.model_validate(payload)
    return model.parse_obj(payload)


def _valid_itinerary_payload() -> dict[str, object]:
    return {
        "destination": "Paris",
        "prompt": "Plan a relaxed day with coffee and art",
        "preferences": [" Relaxed ", " Cafes ", " "],
        "saved_places": [" Louvre Museum ", "Cafe de Flore", ""],
    }


def _fake_openai_success(response_payload: dict[str, object]):
    class FakeCompletions:
        def create(self, *args, **kwargs):
            content = json.dumps(response_payload)
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
    class FakeAPIConnectionError(Exception):
        pass

    class FakeCompletions:
        def create(self, *args, **kwargs):
            raise FakeAPIConnectionError("simulated connection failure")

    class FakeChat:
        def __init__(self):
            self.completions = FakeCompletions()

    class FakeClient:
        def __init__(self, *args, **kwargs):
            self.chat = FakeChat()

    return FakeAPIConnectionError, FakeClient


def test_plan_itinerary_requires_shared_secret(client) -> None:
    response = client.post("/plan-itinerary", json=_valid_itinerary_payload())

    assert response.status_code == 401
    assert response.json() == {"detail": "Unauthorized"}


def test_plan_itinerary_rejects_invalid_shared_secret(client) -> None:
    response = client.post(
        "/plan-itinerary",
        json=_valid_itinerary_payload(),
        headers={"X-CityScout-App-Secret": "wrong-secret"},
    )

    assert response.status_code == 401
    assert response.json() == {"detail": "Unauthorized"}


def test_plan_itinerary_accepts_valid_shared_secret_and_returns_valid_response(
    client,
    auth_headers,
    monkeypatch,
) -> None:
    fake_response = {
        "morning": {"title": "Morning", "activities": ["Coffee near the river", "Visit a museum"]},
        "afternoon": {"title": "Afternoon", "activities": ["Lunch in Le Marais", "Walk a gallery district"]},
        "evening": {"title": "Evening", "activities": ["Dinner in Saint-Germain", "Evening stroll along the Seine"]},
        "notes": ["Mocked itinerary response from the test suite."],
    }
    monkeypatch.setattr(itinerary_service.settings, "require_openai_api_key", lambda: "test-key")
    monkeypatch.setattr(itinerary_service, "OpenAI", _fake_openai_success(fake_response))

    response = client.post("/plan-itinerary", json=_valid_itinerary_payload(), headers=auth_headers)

    assert response.status_code == 200

    payload = response.json()
    validated = _validate_model(ItineraryResponse, payload)

    assert validated.destination == "Paris"
    assert payload["morning"]["activities"] == fake_response["morning"]["activities"]
    assert payload["afternoon"]["activities"] == fake_response["afternoon"]["activities"]
    assert payload["evening"]["activities"] == fake_response["evening"]["activities"]
    assert payload["notes"] == fake_response["notes"]


@pytest.mark.parametrize(
    "payload",
    [
        {
            "destination": "Paris",
            "prompt": "   ",
            "preferences": [],
            "saved_places": [],
        },
        {
            "destination": "   ",
            "prompt": "Plan a relaxed day with coffee and art",
            "preferences": [],
            "saved_places": [],
        },
    ],
)
def test_plan_itinerary_rejects_invalid_payloads(client, auth_headers, payload) -> None:
    response = client.post("/plan-itinerary", json=payload, headers=auth_headers)

    assert response.status_code == 422
    assert isinstance(response.json()["detail"], list)


def test_plan_itinerary_rate_limits_after_threshold(client, auth_headers, monkeypatch) -> None:
    monkeypatch.setattr(rate_limiter, "max_requests", 1)

    response = client.post("/plan-itinerary", json=_valid_itinerary_payload(), headers=auth_headers)
    assert response.status_code == 200

    response = client.post("/plan-itinerary", json=_valid_itinerary_payload(), headers=auth_headers)

    assert response.status_code == 429
    assert response.json() == {"detail": "Rate limit exceeded"}


def test_plan_itinerary_returns_fallback_when_openai_client_fails(
    client,
    auth_headers,
    monkeypatch,
) -> None:
    fake_error, fake_client = _fake_openai_failure()
    monkeypatch.setattr(itinerary_service, "APIConnectionError", fake_error)
    monkeypatch.setattr(itinerary_service, "OpenAI", fake_client)
    monkeypatch.setattr(itinerary_service.settings, "require_openai_api_key", lambda: "test-key")

    response = client.post("/plan-itinerary", json=_valid_itinerary_payload(), headers=auth_headers)

    assert response.status_code == 200

    payload = response.json()
    validated = _validate_model(ItineraryResponse, payload)

    assert validated.destination == "Paris"
    assert any("mocked planning response" in note for note in payload["notes"])
    assert any("backend is ready" in note for note in payload["notes"])
