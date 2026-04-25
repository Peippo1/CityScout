import pytest
from fastapi.testclient import TestClient

from app.core.security import rate_limiter
from app.main import app


client = TestClient(app)
AUTH_HEADERS = {"X-CityScout-App-Secret": "dev-secret"}


@pytest.fixture(autouse=True)
def _reset_rate_limit() -> None:
    rate_limiter.reset()
    yield
    rate_limiter.reset()


def test_guide_message_unauthorized_without_secret() -> None:
    response = client.post(
        "/guide/message",
        json={
            "destination": "Paris",
            "message": "What should I do first?",
            "context": [],
        },
    )

    assert response.status_code == 401




def test_guide_message_rejects_incorrect_secret() -> None:
    response = client.post(
        "/guide/message",
        json={
            "destination": "Paris",
            "message": "Any local etiquette tips?",
            "context": [],
        },
        headers={"X-CityScout-App-Secret": "wrong-secret"},
    )

    assert response.status_code == 401

def test_guide_message_with_valid_payload_returns_reply() -> None:
    response = client.post(
        "/guide/message",
        json={
            "destination": "Paris",
            "message": "What should I know about this city?",
            "context": [],
        },
        headers=AUTH_HEADERS,
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["destination"] == "Paris"
    assert isinstance(payload["reply"], str)
    assert payload["reply"].strip() != ""


def test_guide_message_rejects_empty_message() -> None:
    response = client.post(
        "/guide/message",
        json={
            "destination": "Paris",
            "message": "   ",
            "context": [],
        },
        headers=AUTH_HEADERS,
    )

    assert response.status_code == 422
