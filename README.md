# CityScout

CityScout is a city-first iOS travel companion built with SwiftUI and SwiftData, backed by a FastAPI + OpenAI service for itinerary generation.

It helps people travel like a local with language support, planning tools, and in-trip utility tied to a specific destination.

## Features
- Onboarding and destination selection
- Lessons, phrasebook, and pronunciation practice
- Translate
- Explore with categories and top picks
- Map with saved places, category styling, itinerary focus mode, and route visualisation
- Search across POIs and saved places
- AI itinerary generation with save item, save all, persisted itineraries, regenerate, and itinerary-to-POI matching
- Mapped vs unmatched itinerary distinction
- Light brand system and branded UI pass

## Architecture
- SwiftUI + SwiftData, destination-scoped data model
- FastAPI backend with OpenAI integration for itinerary generation
- Backend validation and tests for reliability

## Current Status
- V1 feature set is in place with destination-scoped flows and local-first persistence
- Itinerary generation and map integration are live in the app
- Backend tests and validation are in place

## Testing Readiness
- Simulator testing is stable for core flows
- Real-device testing requires backend environment configuration (API base URL and server secrets)
- TestFlight is a near-term target

## App Backend Config
- The iOS app reads backend config from generated Info.plist keys when available:
- `CITYSCOUT_API_BASE_URL`
- `CITYSCOUT_APP_SHARED_SECRET`
- For local development, the current defaults still point at `http://127.0.0.1:8000`
- For physical-device testing, set the app target build settings to a reachable backend host instead of localhost

## Backend Setup
```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

## License
CityScout is proprietary and not open source.

© 2026 Tim Finch. All rights reserved.
