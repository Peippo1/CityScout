import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.core.security import rate_limiter


client = TestClient(app)


@pytest.fixture(autouse=True)
def _reset_rate_limit() -> None:
    rate_limiter.reset()
    yield
    rate_limiter.reset()


def test_plan_itinerary_with_valid_payload_returns_expected_shape() -> None:
    response = client.post(
        "/plan-itinerary",
        json={
            "destination": "Paris",
            "prompt": "Plan a relaxed day with coffee and art",
            "preferences": [" Relaxed ", " Cafes ", " "],
            "saved_places": [" Louvre Museum ", "Cafe de Flore", ""],
        },
    )

    assert response.status_code == 200

    payload = response.json()
    assert payload["destination"] == "Paris"

    for block_name in ("morning", "afternoon", "evening"):
        assert block_name in payload
        assert "title" in payload[block_name]
        assert "activities" in payload[block_name]
        assert isinstance(payload[block_name]["activities"], list)

    assert "notes" in payload


def test_plan_itinerary_rejects_empty_prompt() -> None:
    response = client.post(
        "/plan-itinerary",
        json={
            "destination": "Paris",
            "prompt": "   ",
            "preferences": [],
            "saved_places": [],
        },
    )

    assert response.status_code == 422


def test_plan_itinerary_rejects_overly_long_prompt() -> None:
    response = client.post(
        "/plan-itinerary",
        json={
            "destination": "Paris",
            "prompt": "x" * 1001,
            "preferences": [],
            "saved_places": [],
        },
    )

    assert response.status_code == 422


def test_plan_itinerary_rejects_empty_destination() -> None:
    response = client.post(
        "/plan-itinerary",
        json={
            "destination": "   ",
            "prompt": "Plan a day around food and walking",
            "preferences": [],
            "saved_places": [],
        },
    )

    assert response.status_code == 422


def test_plan_itinerary_rate_limits_after_threshold() -> None:
    payload = {
        "destination": "Paris",
        "prompt": "Plan a day around food and walking",
        "preferences": [],
        "saved_places": [],
    }

    for _ in range(20):
        response = client.post("/plan-itinerary", json=payload)
        assert response.status_code == 200

    response = client.post("/plan-itinerary", json=payload)
    assert response.status_code == 429
