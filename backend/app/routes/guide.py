import logging

from fastapi import APIRouter, Depends, Request

from app.core.http import get_request_id
from app.core.security import enforce_rate_limit, verify_app_secret
from app.schemas.guide import GuideMessageRequest, GuideMessageResponse
from app.services.guide_service import generate_guide_reply


router = APIRouter(tags=["guide"])
logger = logging.getLogger(__name__)


@router.post(
    "/guide/message",
    response_model=GuideMessageResponse,
    dependencies=[Depends(verify_app_secret), Depends(enforce_rate_limit)],
)
def guide_message(request: Request, payload: GuideMessageRequest) -> GuideMessageResponse:
    logger.info(
        "Received guide message destination=%s context_count=%s",
        payload.destination,
        len(payload.context),
    )
    response = generate_guide_reply(payload)
    response.request_id = get_request_id(request)
    return response
