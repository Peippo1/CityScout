import logging
import secrets
import time
from collections import deque
from threading import Lock

from fastapi import HTTPException, Request
from starlette.status import HTTP_401_UNAUTHORIZED, HTTP_429_TOO_MANY_REQUESTS, HTTP_500_INTERNAL_SERVER_ERROR

from app.core.config import settings


logger = logging.getLogger(__name__)


class InMemoryRateLimiter:
    def __init__(self, max_requests: int, window_seconds: int) -> None:
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self._hits: dict[str, deque[float]] = {}
        self._lock = Lock()

    def allow(self, key: str, now: float | None = None) -> bool:
        timestamp = now if now is not None else time.time()
        with self._lock:
            entries = self._hits.setdefault(key, deque())
            cutoff = timestamp - self.window_seconds
            while entries and entries[0] < cutoff:
                entries.popleft()
            if len(entries) >= self.max_requests:
                return False
            entries.append(timestamp)
            return True

    def reset(self) -> None:
        with self._lock:
            self._hits.clear()


def _client_ip(request: Request) -> str:
    if request.client and request.client.host:
        return request.client.host
    return "unknown"


rate_limiter = InMemoryRateLimiter(max_requests=20, window_seconds=600)


def verify_app_secret(request: Request) -> None:
    try:
        expected_secret = settings.require_app_shared_secret()
    except RuntimeError as error:
        logger.error("Configuration error category=missing_shared_secret")
        raise HTTPException(status_code=HTTP_500_INTERNAL_SERVER_ERROR, detail=str(error)) from error

    supplied_secret = request.headers.get("X-CityScout-App-Secret")
    if not supplied_secret or not secrets.compare_digest(supplied_secret, expected_secret):
        raise HTTPException(status_code=HTTP_401_UNAUTHORIZED, detail="Unauthorized")


def enforce_rate_limit(request: Request) -> None:
    client_ip = _client_ip(request)
    if not rate_limiter.allow(client_ip):
        logger.warning("Rate limit exceeded category=rate_limited client_ip=%s", client_ip)
        raise HTTPException(status_code=HTTP_429_TOO_MANY_REQUESTS, detail="Rate limit exceeded")
