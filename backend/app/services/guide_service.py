import logging

try:
    from openai import APIConnectionError, APIStatusError, APITimeoutError, OpenAI
except ImportError:  # pragma: no cover - allows fallback behavior in local test environments
    APIConnectionError = APITimeoutError = APIStatusError = Exception
    OpenAI = None

from app.core.config import settings
from app.schemas.guide import GuideMessageRequest, GuideMessageResponse


logger = logging.getLogger(__name__)

MODEL_NAME = "gpt-4o-mini"
SYSTEM_PROMPT = (
    "You are CityScout Guide, a warm, concise, practical local-style tour guide. "
    "Help users understand the city, what they are seeing, what to do next, "
    "and share useful cultural, food, and historical context. "
    "Be helpful, grounded, and not overly verbose. "
    "Keep answers concise, avoid hallucinating specifics, and suggest practical next actions."
)

DEFAULT_PROMPTS = [
    "What should I know about this city?",
    "Give me a short walking tour",
    "What food should I try?",
    "Tell me something interesting nearby",
]


def generate_guide_reply(request: GuideMessageRequest) -> GuideMessageResponse:
    destination = request.destination or "your destination"

    logger.info(
        "Generating guide reply destination=%s context_count=%s",
        destination,
        len(request.context),
    )

    try:
        if OpenAI is None:
            raise RuntimeError("OpenAI SDK is not installed.")

        client = OpenAI(api_key=settings.require_openai_api_key(), timeout=20.0, max_retries=1)
        completion = client.chat.completions.create(
            model=MODEL_NAME,
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": _build_user_message(request, destination)},
            ],
        )
        content = completion.choices[0].message.content
        if not content:
            raise ValueError("OpenAI returned an empty response.")

        return GuideMessageResponse(
            destination=destination,
            reply=content.strip(),
            suggested_prompts=DEFAULT_PROMPTS,
        )
    except RuntimeError:
        logger.error("Guide generation failed category=config_error destination=%s", destination)
    except APITimeoutError:
        logger.error("Guide generation failed category=openai_timeout destination=%s", destination)
    except APIConnectionError:
        logger.error("Guide generation failed category=openai_connection_error destination=%s", destination)
    except APIStatusError as error:
        logger.error(
            "Guide generation failed category=openai_status_error destination=%s status=%s request_id=%s",
            destination,
            error.status_code,
            getattr(error, "request_id", None),
        )
    except ValueError:
        logger.error("Guide generation failed category=empty_response destination=%s", destination)
    except Exception:
        logger.exception("Guide generation failed category=unexpected destination=%s", destination)

    return _fallback_guide_reply(destination)


def _build_user_message(request: GuideMessageRequest, destination: str) -> str:
    context_lines = "\n".join(f"- {line}" for line in request.context if line.strip())
    if not context_lines:
        context_lines = "- (none)"

    return (
        f"Destination: {destination}\n"
        f"User message: {request.message.strip()}\n"
        "Recent context:\n"
        f"{context_lines}\n"
        "Provide a concise travel-friendly response."
    )


def _fallback_guide_reply(destination: str) -> GuideMessageResponse:
    return GuideMessageResponse(
        destination=destination,
        reply=(
            f"I can still help with {destination}. Start with a central area walk, pick one landmark, "
            "then add a local food stop nearby. If you share your pace or interests, I can tailor it."
        ),
        suggested_prompts=DEFAULT_PROMPTS,
    )
