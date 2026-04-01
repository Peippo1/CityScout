# CityScout Known Issues

## Real-Device Backend Configuration
- `AppEnvironment` still defaults to a local development backend
- `127.0.0.1` works for simulator-on-Mac workflows but not for physical devices
- A device-safe backend configuration path is still needed before broader testing

## Shared Secret / Private Testing Setup
- The app currently uses a shared-secret header for backend access
- This is enough for private testing but is not full account-based authentication
- Misconfigured secrets currently surface as service failures rather than a richer auth flow

## Itinerary Matching Limits
- `ItineraryPlaceMatcher` is conservative by design
- Strong POI references usually resolve; generic activity text often falls back intentionally
- Fallback saved itinerary places may have inferred categories and zero coordinates
- Route visualization is only meaningful when itinerary items resolve to real coordinates

## Localhost / Simulator Assumptions
- Several development flows assume the backend is running on the same Mac as the simulator
- This is fragile for real-device testing and TestFlight preparation

## SwiftData Development Caveat
- Schema changes can leave an existing local store unreadable during development
- `CityScoutApp` falls back to an in-memory store if the persistent store fails to open
- This keeps the app runnable but means data is not persisted for that session

## Pre-TestFlight Hardening Items
- Backend host/config strategy for physical devices
- Stability pass on itinerary generation and regeneration
- Map centering and device-specific polish
- Clarity around mapped vs fallback itinerary items
- Reliability checks for saved places and saved itineraries after relaunch
