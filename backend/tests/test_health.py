def test_health_returns_ok(client) -> None:
    response = client.get("/health")

    assert response.status_code == 200
    payload = response.json()

    assert payload["status"] == "ok"
    assert isinstance(payload["request_id"], str)
    assert payload["request_id"].strip()
    assert response.headers["X-Request-Id"] == payload["request_id"]
    assert response.headers["X-Content-Type-Options"] == "nosniff"
