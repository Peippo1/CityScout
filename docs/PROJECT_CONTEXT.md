# CityScout – Project Context

## Product Vision
CityScout is an offline-first iOS travel companion that helps users access essential city phrases and guidance reliably, even with poor or no connectivity.

## Current Phase
V1 stabilisation

## Core Principles
- Offline-first by default for critical user journeys.
- Predictable navigation with stable flows and minimal surprises.
- Clean architecture with clear boundaries between UI, domain logic, and data.
- Feature-first folder structure.
- No business logic inside SwiftUI views.

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
- Seed data is loaded from `Resources/SeedContent/*.json` (currently Barcelona and Paris content).
- Seed imports must be idempotent: re-running a seed import must not duplicate records or corrupt state.
- Seed version flags must gate migrations/imports so each seed version is applied exactly as intended.
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
- Offline-first behavior is preserved for core V1 flows.
- Navigation paths are predictable and stable.
- Seed import path remains idempotent and version-gated.
- No regressions to architecture rules or coding standards above.
- CI build and tests pass on the configured workflow.

## Current Status
- Barcelona + Paris seed data working.
- Lessons navigation working.
- `DebugDiagnostics.swift` exists for logging (safe to remove before production).
