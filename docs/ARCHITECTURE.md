# CityScout Architecture

## Overview
CityScout is a city-first iOS travel companion built with SwiftUI and SwiftData. The app is local-first for core content and saved state. A small FastAPI backend is used only for itinerary generation.

## Repository Shape
```text
CityScout/
├── App/
├── Core/
├── Features/
├── Models/
├── Resources/
├── Services/
backend/
└── app/
docs/
```

## Root App Flow
- `CityScoutApp` creates the SwiftData `ModelContainer`.
- `ContentView` decides the root path:
- onboarding not seen -> `OnboardingFlowView`
- onboarding complete but no destination selected -> `DestinationPickerView`
- destination selected -> `TripShellView`
- `TripShellView` is the main tab shell:
- Plan
- Map
- Phrasebook
- Translate
- More

## Feature Areas
- `Plan`: itinerary generation, save item/save all, saved itineraries
- `Map`: saved places, itinerary-only filter, route visualization
- `Phrasebook`: saved phrases and recent practice
- `Translate`: short phrase translation using Apple Translation when available
- `Lessons`: destination-specific situations and phrases from seeded content
- `Explore`: curated POIs by category and top picks
- `Search`: destination POIs plus saved places

## Backend Role
- Backend lives under `backend/`
- Exposes:
- `GET /health`
- `POST /plan-itinerary`
- OpenAI usage stays in the backend
- App secrets stay in backend/environment config, not in SwiftUI views
- Current backend protection is deployment-side configuration plus in-memory rate limiting, pending stronger production auth controls

## Data Flow Summary
- Seed JSON files in `Resources/SeedContent/` bootstrap destination data into SwiftData
- Destination selection scopes app behaviour by `destinationName`
- Most app reads/writes are local SwiftData operations
- `PlanAPIService` sends itinerary requests to the backend and decodes the response
- Itinerary activities can be resolved to known POIs through `ItineraryPlaceMatcher`
- Matched or fallback activities can be saved as `SavedPlace` entries for map/search flows

## Architectural Boundaries
- Keep business logic out of SwiftUI views where practical; use feature-local or shared services
- Keep AI logic and API keys out of the app
- Keep destination scoping explicit in queries and persistence
- Preserve local-first behaviour even when backend requests fail
