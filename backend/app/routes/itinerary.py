import logging

from fastapi import APIRouter

from app.schemas.itinerary import ItineraryRequest, ItineraryResponse
from app.services.itinerary_service import generate_itinerary


router = APIRouter(tags=["itinerary"])
logger = logging.getLogger(__name__)


@router.post("/plan-itinerary", response_model=ItineraryResponse)
def plan_itinerary(request: ItineraryRequest) -> ItineraryResponse:
    logger.info(
        "Received itinerary request destination=%s preferences_count=%s saved_places_count=%s",
        request.destination,
        len(request.preferences),
        len(request.saved_places),
    )
    return generate_itinerary(request)
