from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.routes.itinerary import router as itinerary_router


app = FastAPI(title="CityScout Backend", version="0.1.0")

cors_origins = settings.cors_origins()
if cors_origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=cors_origins,
        allow_credentials=False,
        allow_methods=["GET", "POST", "OPTIONS"],
        allow_headers=["Content-Type"],
    )


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


app.include_router(itinerary_router)
