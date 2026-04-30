from pydantic import BaseModel, Field

try:
    from pydantic import field_validator

    PYDANTIC_V2 = True
except ImportError:  # pragma: no cover - compatibility for older Pydantic
    from pydantic import validator as field_validator

    PYDANTIC_V2 = False


class GuideMessageRequest(BaseModel):
    destination: str = Field(..., min_length=1, max_length=80)
    message: str = Field(..., min_length=1, max_length=1000)
    context: list[str] = Field(default_factory=list)

    @field_validator("destination", "message", mode="before") if PYDANTIC_V2 else field_validator("destination", "message", pre=True)
    @classmethod
    def _strip_text_fields(cls, value: str) -> str:
        return value.strip() if isinstance(value, str) else value

    @field_validator("context", mode="before") if PYDANTIC_V2 else field_validator("context", pre=True)
    @classmethod
    def _normalize_context(cls, value: list[str] | None) -> list[str]:
        if not value:
            return []

        normalized_items: list[str] = []
        for item in value:
            if not isinstance(item, str):
                normalized_items.append(item)
                continue
            trimmed = item.strip()
            if trimmed:
                normalized_items.append(trimmed)
        return normalized_items

    @field_validator("context") if PYDANTIC_V2 else field_validator("context")
    @classmethod
    def _validate_context_length(cls, value: list[str]) -> list[str]:
        if len(value) > 20:
            raise ValueError("context must contain at most 20 items")
        return value


class GuideMessageResponse(BaseModel):
    destination: str
    reply: str
    suggested_prompts: list[str] = Field(default_factory=list)
    request_id: str | None = None
