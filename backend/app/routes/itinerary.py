import logging

from fastapi import APIRouter, Depends, Request

from app.core.http import get_request_id
from app.core.security import enforce_rate_limit, verify_app_secret
from app.schemas.itinerary import ItineraryRequest, ItineraryResponse
from app.services.itinerary_service import generate_itinerary


router = APIRouter(tags=["itinerary"])
logger = logging.getLogger(__name__)


@router.post(
    "/plan-itinerary",
    response_model=ItineraryResponse,
    dependencies=[Depends(verify_app_secret), Depends(enforce_rate_limit)],
)
def plan_itinerary(request: Request, payload: ItineraryRequest) -> ItineraryResponse:
    logger.info(
        "Received itinerary request destination=%s preferences_count=%s saved_places_count=%s",
        payload.destination,
        len(payload.preferences),
        len(payload.saved_places),
    )
    response = generate_itinerary(payload)
    response.request_id = get_request_id(request)
    return response
