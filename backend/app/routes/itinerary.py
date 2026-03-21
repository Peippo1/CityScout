from fastapi import APIRouter

from app.schemas.itinerary import ItineraryRequest, ItineraryResponse
from app.services.itinerary_service import generate_itinerary


router = APIRouter(tags=["itinerary"])


@router.post("/plan-itinerary", response_model=ItineraryResponse)
def plan_itinerary(request: ItineraryRequest) -> ItineraryResponse:
    return generate_itinerary(request)
