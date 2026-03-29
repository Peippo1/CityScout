# CityScout – Project Context

## Product Vision
CityScout is a city-first iOS travel companion that helps people travel like a local. It is language-first but not language-only, combining learning, planning, and in-trip utility in a premium, soft, modern brand direction.

## Current Phase
Pre-TestFlight hardening

## Core Principles
- Destination-scoped UX and data model.
- Local-first persistence for core flows.
- Clear boundary between app and backend API.
- Predictable navigation with stable flows.
- Feature-first folder structure.
- No business logic inside SwiftUI views.

## Current UX Direction
- Calm, premium, soft visual language with restrained color and strong typography.
- City-first framing across onboarding, explore, map, and plan.
- Planning and in-trip usage should feel seamless, not separate modes.
- Clarity over density: prioritize legibility and confident defaults.

## Do Not Break
- Destination-scoped architecture (all data and queries scoped to a selected city).
- Local-first persistence for saved places and itineraries.
- Backend API boundary (no OpenAI keys or AI logic in the app).
- Category-aware integration across map, search, and planning.

## Repository Structure
```text
CityScout/
├── App/
├── Features/
├── Models/
├── Services/
├── Resources/
└── Core/
```

## Data Layer

### Seed System Rules
- Seed data is loaded from `Resources/SeedContent/*.json` for multiple cities.
- Seed imports must be idempotent: re-running a seed import must not duplicate records or corrupt state.
- Seed version flags must gate migrations/imports so each seed version is applied exactly once.
- `SeedBootstrapper` runs at startup and should only apply new/required seed versions.

### SwiftData Guardrails
- Do not compare SwiftData model objects inside `#Predicate` closures.
- Always compare stable scalar fields (for example IDs or primitive properties) instead of model instances.
- Capture IDs outside the predicate before entering the closure.
- Keep persistence/query logic in Services, not in Views.

#### Concrete Example

❌ Incorrect (will crash or behave unpredictably):
```swift
#Predicate { phrase in phrase.situation == situation }
```

❌ Also unsafe (captures model instance directly):
```swift
#Predicate { situation in situation.trip == trip }
```

✅ Correct pattern (capture ID first):
```swift
let situationID = situation.id
#Predicate<Phrase> { phrase in
    phrase.situation?.id == situationID
}
```

✅ Correct for Trip relationship:
```swift
let tripID = trip.id
#Predicate<Situation> { situation in
    situation.trip?.id == tripID
}
```

This rule is critical. Most navigation crashes in SwiftData-based apps come from incorrect predicate comparisons between model instances instead of stable scalar identifiers.

## Coding Standards for Codex
1. Do not rename project files unless explicitly asked.
2. Do not modify the bundle identifier.
3. Do not introduce third-party dependencies.
4. Keep SwiftUI-first.
5. Do not use UIKit unless explicitly requested.
6. Avoid force unwraps.
7. Avoid global state.

## CI Expectations
- CI must build `CityScout.xcodeproj` using scheme `CityScout`.
- CI must run build and test steps against an iOS Simulator destination.

## Build & Run
- Project: `CityScout.xcodeproj`
- Target: `CityScout`
- Scheme: `CityScout`

## Definition of Done
- Feature behavior matches scope and is testable in simulator.
- Destination-scoped architecture and local-first persistence are preserved.
- Navigation paths are predictable and stable.
- Seed import path remains idempotent and version-gated.
- No regressions to architecture rules or coding standards above.
- CI build and tests pass on the configured workflow.

## Current Status
- Destination-scoped onboarding, explore, map, search, and planning are live.
- Itinerary generation, save item/all, and persistence are in place.
- Backend validation and tests cover itinerary generation.
