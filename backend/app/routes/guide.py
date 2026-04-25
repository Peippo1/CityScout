import logging

from fastapi import APIRouter, Depends

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
def guide_message(request: GuideMessageRequest) -> GuideMessageResponse:
    logger.info(
        "Received guide message destination=%s context_count=%s",
        request.destination,
        len(request.context),
    )
    return generate_guide_reply(request)
