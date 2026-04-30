import os
import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient


BACKEND_DIR = Path(__file__).resolve().parents[1]
TEST_SECRET = "test-secret"

os.environ.setdefault("APP_SHARED_SECRET", TEST_SECRET)

if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from app.core.security import rate_limiter
from app.main import app


@pytest.fixture(scope="session")
def auth_headers() -> dict[str, str]:
    return {"X-CityScout-App-Secret": TEST_SECRET}


@pytest.fixture()
def client() -> TestClient:
    return TestClient(app)


@pytest.fixture(autouse=True)
def reset_rate_limiter() -> None:
    rate_limiter.reset()
    yield
    rate_limiter.reset()
