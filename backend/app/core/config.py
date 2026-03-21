import os

from dotenv import load_dotenv
from pydantic import BaseModel


load_dotenv()


class Settings(BaseModel):
    openai_api_key: str | None = os.getenv("OPENAI_API_KEY")

    def require_openai_api_key(self) -> str:
        if self.openai_api_key:
            return self.openai_api_key

        raise RuntimeError(
            "OPENAI_API_KEY is missing. Set it in the environment or backend/.env before calling OpenAI."
        )


settings = Settings()
