# CityScout Release Plan

## Current State
- City-first onboarding and destination-scoped experience
- Lessons, phrasebook, pronunciation, and translate
- Explore with categories and top picks
- Map with saved places, category styling, itinerary focus mode, and route visualisation
- Search across POIs and saved places
- AI itinerary generation with save item, save all, persisted itineraries, and regenerate
- Itinerary-to-POI matching with mapped vs unmatched distinction
- FastAPI + OpenAI backend with validation and tests

## Required Before TestFlight
- Real-device readiness with backend environment configuration (API base URL and server secrets)
- Stable map centering and device-specific polish
- Itinerary refinement UX (clarity between mapped vs unmatched items, save flows)
- Smarter place resolution for itinerary items
- Basic crash-free pass on core flows

## Required Before Broader Beta
- Reliability pass on itinerary generation and regeneration quality
- Performance and battery checks on real devices
- Clear onboarding and destination switching UX
- QA coverage for saved places, saved itineraries, and persistence

## Smoke Test Checklist
- Onboarding completes and destination is selected
- Lessons load and pronunciation plays
- Phrasebook saves and search works
- Translate returns results
- Explore shows categories and top picks
- Save a place from Explore and see it on Map
- Map shows category styling, focus mode, and route visualisation
- Search returns POIs and saved places
- Generate an itinerary, save an item, save all
- Itineraries persist after app relaunch
- Regenerate itinerary without breaking saved items
