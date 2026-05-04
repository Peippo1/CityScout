import json
import logging

try:
    from openai import APIConnectionError, APIStatusError, APITimeoutError, OpenAI
except ImportError:  # pragma: no cover - allows fallback behavior in local test environments
    APIConnectionError = APITimeoutError = APIStatusError = Exception
    OpenAI = None

from fastapi import HTTPException
from starlette.status import HTTP_502_BAD_GATEWAY, HTTP_503_SERVICE_UNAVAILABLE

from app.core.config import settings
from app.schemas.itinerary import ItineraryBlock, ItineraryRequest, ItineraryResponse


logger = logging.getLogger(__name__)

SYSTEM_PROMPT = """You are a travel planning assistant.
Generate a one-day itinerary for a user in a specific city.

Return ONLY valid JSON with the following structure:
{
  "morning": { "title": "...", "activities": ["...", "..."] },
  "afternoon": { "title": "...", "activities": ["...", "..."] },
  "evening": { "title": "...", "activities": ["...", "..."] },
  "notes": ["...", "..."]
}

Do not include any explanation or extra text."""

MODEL_NAME = "gpt-4o-mini"


def generate_itinerary(request: ItineraryRequest) -> ItineraryResponse:
    destination = request.destination or "your destination"
    preferences = _normalize_preferences(request.preferences)

    logger.info(
        "Generating itinerary destination=%s preferences_count=%s saved_places_count=%s",
        destination,
        len(preferences),
        len(request.saved_places),
    )

    try:
        if OpenAI is None:
            raise RuntimeError("OpenAI SDK is not installed.")

        client = OpenAI(api_key=settings.require_openai_api_key(), timeout=20.0, max_retries=1)
        completion = client.chat.completions.create(
            model=MODEL_NAME,
            response_format={"type": "json_object"},
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": _build_user_prompt(request, destination, preferences)},
            ],
        )
        content = completion.choices[0].message.content
        if not content:
            raise ValueError("OpenAI returned an empty response.")
        return _parse_itinerary_response(content, destination)
    except RuntimeError:
        logger.error("Itinerary generation failed category=config_error destination=%s", destination)
        if _should_use_mock_fallback():
            return _generate_fallback_itinerary(request)
        raise
    except APITimeoutError:
        logger.error("Itinerary generation failed category=openai_timeout destination=%s", destination)
        if _should_use_mock_fallback():
            return _generate_fallback_itinerary(request)
        raise HTTPException(
            status_code=HTTP_503_SERVICE_UNAVAILABLE,
            detail="Itinerary generation is temporarily unavailable.",
        )
    except APIConnectionError:
        logger.error("Itinerary generation failed category=openai_connection_error destination=%s", destination)
        if _should_use_mock_fallback():
            return _generate_fallback_itinerary(request)
        raise HTTPException(
            status_code=HTTP_502_BAD_GATEWAY,
            detail="Itinerary generation is temporarily unavailable.",
        )
    except APIStatusError as error:
        logger.error(
            "Itinerary generation failed category=openai_status_error destination=%s status=%s request_id=%s",
            destination,
            error.status_code,
            getattr(error, "request_id", None),
        )
        if _should_use_mock_fallback():
            return _generate_fallback_itinerary(request)
        raise HTTPException(
            status_code=HTTP_502_BAD_GATEWAY,
            detail="Itinerary generation is temporarily unavailable.",
        )
    except (json.JSONDecodeError, ValueError):
        logger.error("Itinerary generation failed category=invalid_json destination=%s", destination)
        if _should_use_mock_fallback():
            return _generate_fallback_itinerary(request)
        raise HTTPException(
            status_code=HTTP_502_BAD_GATEWAY,
            detail="Itinerary generation returned an invalid response.",
        )
    except Exception:
        logger.exception("Itinerary generation failed category=unexpected destination=%s", destination)
        if _should_use_mock_fallback():
            return _generate_fallback_itinerary(request)
        raise

    return _generate_fallback_itinerary(request)


def _build_user_prompt(
    request: ItineraryRequest,
    destination: str,
    preferences: list[str],
) -> str:
    saved_places = [place.strip() for place in request.saved_places if place.strip()]
    prompt = request.prompt.strip() or "No additional prompt provided."

    payload = {
        "destination": destination,
        "prompt": prompt,
        "preferences": preferences,
        "saved_places": saved_places,
        "constraints": [
            "Create a realistic one-day city itinerary.",
            "Keep the plan concise, practical, and traveler-friendly.",
            "Use saved places when they fit naturally.",
            "Return exactly two activities per time block when possible.",
        ],
    }
    return json.dumps(payload, ensure_ascii=True)


def _parse_itinerary_response(content: str, destination: str) -> ItineraryResponse:
    raw_payload = json.loads(content)
    raw_payload["destination"] = destination

    if hasattr(ItineraryResponse, "model_validate"):
        return ItineraryResponse.model_validate(raw_payload)
    return ItineraryResponse.parse_obj(raw_payload)


def _generate_fallback_itinerary(request: ItineraryRequest) -> ItineraryResponse:
    destination = request.destination or "your destination"
    preferences = _normalize_preferences(request.preferences)
    saved_places = [place.strip() for place in request.saved_places if place.strip()]
    prompt = request.prompt

    morning_activities = [
        _morning_opening(destination, preferences, prompt),
        _saved_place_line(saved_places, "morning", destination),
    ]

    afternoon_activities = [
        _afternoon_opening(destination, preferences),
        _afternoon_follow_up(destination, preferences, saved_places),
    ]

    evening_activities = [
        _evening_opening(destination, preferences),
        _evening_follow_up(destination, prompt),
    ]

    notes = [
        f"This is a mocked planning response for {destination}.",
        "The backend is ready for a future AI itinerary service integration.",
    ]
    if preferences:
        notes.append(f"Preferences considered: {', '.join(preferences)}.")
    if saved_places:
        notes.append(f"Saved places included where possible: {', '.join(saved_places[:2])}.")

    return ItineraryResponse(
        destination=destination,
        morning=ItineraryBlock(title="Morning", activities=morning_activities),
        afternoon=ItineraryBlock(title="Afternoon", activities=afternoon_activities),
        evening=ItineraryBlock(title="Evening", activities=evening_activities),
        notes=notes,
    )


def _normalize_preferences(preferences: list[str]) -> list[str]:
    ordered_unique: list[str] = []
    for preference in preferences:
        normalized = preference.strip()
        if normalized and normalized not in ordered_unique:
            ordered_unique.append(normalized)
    return ordered_unique


def _should_use_mock_fallback() -> bool:
    return settings.app_env() in {"development", "test"}


def _morning_opening(destination: str, preferences: list[str], prompt: str) -> str:
    if "caf" in " ".join(preferences).lower():
        return f"Start the day with coffee and a light breakfast in {destination}."
    if "relaxed" in " ".join(preferences).lower():
        return f"Begin with an easy-paced walk through a local neighborhood in {destination}."
    if prompt:
        return f"Start with a morning plan shaped around \"{prompt}\" in {destination}."
    return f"Start the day with a comfortable introduction to {destination}."


def _saved_place_line(saved_places: list[str], period: str, destination: str) -> str:
    if saved_places:
        return f"Use {saved_places[0]} as a {period} anchor while exploring {destination}."
    return f"Leave time for a flexible stop that feels local to {destination}."


def _afternoon_opening(destination: str, preferences: list[str]) -> str:
    joined = " ".join(preferences).lower()
    if "sight" in joined:
        return f"Spend the afternoon at one of {destination}'s major sights."
    if "food" in joined:
        return f"Plan the afternoon around a standout lunch and food stop in {destination}."
    return f"Use the afternoon for a balanced mix of exploration and downtime in {destination}."


def _afternoon_follow_up(destination: str, preferences: list[str], saved_places: list[str]) -> str:
    joined = " ".join(preferences).lower()
    if len(saved_places) > 1:
        return f"Continue toward {saved_places[1]} to add a personal stop to the route."
    if "shop" in joined:
        return f"Add time for shopping and browsing in a busy part of {destination}."
    return f"Pause for lunch and a short reset before continuing through {destination}."


def _evening_opening(destination: str, preferences: list[str]) -> str:
    joined = " ".join(preferences).lower()
    if "night" in joined:
        return f"Wrap up with a lively evening area and a late dinner in {destination}."
    if "food" in joined:
        return f"End with a memorable dinner that highlights local flavors in {destination}."
    return f"Finish the day with dinner and a relaxed walk in {destination}."


def _evening_follow_up(destination: str, prompt: str) -> str:
    if prompt:
        return f"Keep the evening aligned with your request: \"{prompt}\"."
    return f"Leave the final stop open so the plan can adapt once you are in {destination}."
