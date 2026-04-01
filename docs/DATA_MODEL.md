# CityScout Data Model

## Persistence Approach
- SwiftData is the primary persistence layer in the iOS app
- Core flows are local-first
- Seed content is imported from bundled JSON files at startup
- Backend responses are not persisted automatically; the app chooses what to save

## SwiftData Models

### `Trip`
- Represents a seeded destination
- Key fields:
- `destinationName`
- `baseLanguage`
- `targetLanguage`
- Used to drive destination-scoped lessons/content

### `Situation`
- Belongs to a `Trip`
- Groups lesson phrases by travel context
- Key fields:
- `trip`
- `title`
- `sortOrder`

### `Phrase`
- Belongs to a `Situation`
- Stores a target-language phrase and English meaning
- Key fields:
- `situation`
- `targetText`
- `englishMeaning`
- `notes`
- `tagsCSV`

### `SavedPhrase`
- User-saved phrasebook entry
- Destination-scoped
- Also stores practice metadata such as `lastPracticedAt`

### `SavedPlace`
- User-saved place for map/search flows
- Destination-scoped
- Can come from:
- manual creation
- POI save
- itinerary-derived save
- Key fields:
- `name`
- `categoryRaw`
- `source`
- `destinationName`
- `latitude`
- `longitude`

### `SavedItinerary`
- Persisted snapshot of a generated itinerary
- Destination-scoped
- Stores prompt, preferences, morning/afternoon/evening blocks, and notes
- Uses CSV-backed string storage for arrays

## Relationships
- `Trip` -> many `Situation`
- `Situation` -> many `Phrase`
- `SavedPhrase`, `SavedPlace`, and `SavedItinerary` are scoped by `destinationName`

## Destination Scoping
- The app does not treat content as globally shared across cities
- Queries for saved places and saved itineraries should always include `destinationName`
- When comparing related SwiftData records, compare scalar values such as `id` or `destinationName`, not model instances

## Seed Data Notes
- Seed packs live in `CityScout/Resources/SeedContent/*.json`
- `SeedBootstrapper` imports them at startup
- Seed import is intended to be idempotent and version-gated
