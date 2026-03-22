from pydantic import BaseModel, Field

try:
    from pydantic import field_validator

    PYDANTIC_V2 = True
except ImportError:  # pragma: no cover - compatibility for older Pydantic
    from pydantic import validator as field_validator

    PYDANTIC_V2 = False


class ItineraryRequest(BaseModel):
    destination: str = Field(..., min_length=1, max_length=80)
    prompt: str = Field(..., min_length=1, max_length=1000)
    preferences: list[str] = Field(default_factory=list)
    saved_places: list[str] = Field(default_factory=list)

    @field_validator("destination", "prompt", mode="before") if PYDANTIC_V2 else field_validator("destination", "prompt", pre=True)
    @classmethod
    def _strip_text_fields(cls, value: str) -> str:
        return value.strip() if isinstance(value, str) else value

    @field_validator("preferences", "saved_places", mode="before") if PYDANTIC_V2 else field_validator("preferences", "saved_places", pre=True)
    @classmethod
    def _normalize_string_lists(cls, value: list[str] | None) -> list[str]:
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

    @field_validator("preferences") if PYDANTIC_V2 else field_validator("preferences")
    @classmethod
    def _validate_preferences_length(cls, value: list[str]) -> list[str]:
        if len(value) > 10:
            raise ValueError("preferences must contain at most 10 items")
        return value

    @field_validator("saved_places") if PYDANTIC_V2 else field_validator("saved_places")
    @classmethod
    def _validate_saved_places_length(cls, value: list[str]) -> list[str]:
        if len(value) > 25:
            raise ValueError("saved_places must contain at most 25 items")
        return value


class ItineraryBlock(BaseModel):
    title: str
    activities: list[str]


class ItineraryResponse(BaseModel):
    destination: str
    morning: ItineraryBlock
    afternoon: ItineraryBlock
    evening: ItineraryBlock
    notes: list[str] = Field(default_factory=list)
