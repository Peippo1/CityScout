import os

from dotenv import load_dotenv


load_dotenv()

_ALLOWED_ENVS = {"development", "test", "staging", "production"}


def _read_env(name: str) -> str | None:
    value = os.getenv(name)
    if value is None:
        return None
    stripped = value.strip()
    return stripped if stripped else None


class Settings:
    def app_env(self) -> str:
        value = (_read_env("APP_ENV") or "development").lower()
        if value not in _ALLOWED_ENVS:
            raise RuntimeError(f"APP_ENV must be one of {sorted(_ALLOWED_ENVS)}. Got: {value}.")
        return value

    def require_openai_api_key(self) -> str:
        key = _read_env("OPENAI_API_KEY")
        if key:
            return key
        raise RuntimeError(
            "OPENAI_API_KEY is missing. Set it in the environment or backend/.env before calling OpenAI."
        )

    def require_app_shared_secret(self) -> str:
        secret = _read_env("APP_SHARED_SECRET")
        if secret:
            if self.app_env() in {"staging", "production"} and len(secret) < 16:
                raise RuntimeError("APP_SHARED_SECRET must be at least 16 characters in staging/production.")
            return secret
        if self.app_env() in {"development", "test"}:
            return "change_me_for_private_testing"
        raise RuntimeError(
            "APP_SHARED_SECRET is missing. Set it in the environment or backend/.env before accepting authenticated requests."
        )

    def cors_origins(self) -> list[str]:
        origins: list[str] = []
        if self.app_env() in {"development", "test"}:
            origins.extend(
                [
                    "http://localhost:3000",
                    "http://127.0.0.1:3000",
                    "http://localhost:5173",
                    "http://127.0.0.1:5173",
                ]
            )

        extra_origin = _read_env("APP_ALLOWED_ORIGIN")
        if extra_origin:
            origins.append(extra_origin)

        extra_origins = _read_env("APP_ALLOWED_ORIGINS")
        if extra_origins:
            origins.extend([item.strip() for item in extra_origins.split(",") if item.strip()])

        deduped: list[str] = []
        seen: set[str] = set()
        for origin in origins:
            if origin not in seen:
                seen.add(origin)
                deduped.append(origin)
        return deduped


settings = Settings()
