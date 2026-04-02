# CityScout Conventions

## Architecture Rules
- Keep CityScout city-first and destination-scoped
- Keep core app behaviour local-first
- Keep AI logic and secrets in the backend only
- Do not introduce third-party iOS dependencies without explicit approval
- Prefer small, explicit services over large abstractions

## SwiftUI Boundaries
- SwiftUI views should focus on rendering, navigation, and local UI state
- Persistence, matching, seed import, and backend communication should live in services or small feature-local helpers
- Avoid large rewrites unless the task explicitly calls for one

## SwiftData Rules
- Do not compare SwiftData model instances inside `#Predicate`
- Compare scalar values such as `id`, `destinationName`, or other primitive fields
- Capture scalar values outside predicates before building the predicate closure
- Keep fetch/save/delete logic out of deeply nested view code where practical

## Destination Scope Rules
- Saved places, saved itineraries, and lesson content must stay scoped to the selected destination
- Do not create cross-city queries for convenience if the feature is city-specific
- Duplicate prevention should be destination-aware

## Backend Rules
- The backend is used only for itinerary generation
- Do not put OpenAI models, API keys, or prompt orchestration into the iOS app
- Preserve the current backend contract unless there is a clear reason to change both sides

## Refactor Guidance
- Prefer small, high-value refactors
- Keep feature structure intact unless a broader change is explicitly requested
- If moving logic out of a view, prefer a feature-local coordinator/helper before creating a global abstraction

## Debugging Guidance
- Keep diagnostics debug-only when possible
- Avoid shipping noisy prints in release behaviour
