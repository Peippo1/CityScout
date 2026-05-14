# CityScout — Offline Strategy

This document describes the offline-first architecture principles for CityScout content, the current sync boundaries, and the intended path toward full offline city packs and iOS parity.

No offline sync is implemented yet. This document defines the intended architecture so that data structures, type contracts, and schema decisions are made with it in mind.

---

## Philosophy

CityScout content falls into two categories:

**Static contextual content** — Local Intelligence tips, History & Mythology stories, Walking Narratives. This content does not change between user sessions. It is deterministic, versionable, and safe to cache indefinitely until a new app version ships with updated seed data.

**User-scoped dynamic content** — Saved itineraries, journal entries. This content is user-owned and stored in Supabase. It requires authentication and a network connection to read or write.

The offline-first strategy is: ship static contextual content in the app bundle, sync user-scoped content opportunistically when online.

---

## Current sync boundaries

| Content | Online required? | Cacheable? | Where stored |
| --- | --- | --- | --- |
| Itinerary generation | Yes | Generated output only | Backend (OpenAI) → Supabase |
| Local Intelligence tips | No | Yes — static seed | App bundle (`lib/local-intelligence/seed.ts`) |
| History & Mythology | No | Yes — static seed | App bundle (`lib/history-mythology/seed.ts`) |
| Saved itineraries | Yes (save/load) | `structured_itinerary_json` portable | Supabase |
| Journal entries | Yes | No (user-private) | Supabase |
| Auth session | Yes | Token cached in cookie | Supabase Auth |

---

## Offline-portable types

The `CityPack` type (`web/types/offline.ts`) is the canonical portable bundle:

```typescript
interface CityPack {
  schemaVersion: string;      // matches CITYSCOUT_CONTENT_VERSION
  builtAt: string;            // ISO 8601
  destination: string;
  intelligence: DestinationIntelligence | null;
  historyMythology: PlaceHistoryMythology | null;
  structuredItinerary: StructuredItinerary | null;
}
```

This type is:
- **Deterministic** — same destination + same seed version = same pack
- **Serialisable** — plain JSON, no functions, no class instances
- **Versionable** — `schemaVersion` allows clients to detect stale caches
- **Extensible** — add `walkingNarrative`, `localGuide`, etc. as nullable fields

`buildCityPack(destination)` assembles a `CityPack` from the current seed data. It is a pure synchronous function with no network dependency.

---

## Schema versioning

Each seed file exports a version constant:

```typescript
// lib/local-intelligence/seed.ts
export const LOCAL_INTELLIGENCE_SEED_VERSION = "1.0.0";

// lib/history-mythology/seed.ts
export const HISTORY_MYTHOLOGY_SEED_VERSION = "1.0.0";
```

`CITYSCOUT_CONTENT_VERSION` in `types/offline.ts` is the combined content version. **Bump this constant whenever any seed file changes in a way that affects rendered output.** Clients (iOS, web) should compare their cached version against the current app version to decide whether to invalidate their local cache.

Versioning rules:
- Patch version (`1.0.x`): copy corrections, typo fixes
- Minor version (`1.x.0`): new destinations added
- Major version (`x.0.0`): type-breaking schema changes

---

## Stale data handling

Web: contextual content is always current because it is bundled with the app. No staleness problem until a re-deploy ships updated seeds.

iOS (current): no offline caching yet. Each launch fetches from the backend.

iOS (target): the app ships with a bundled city pack per destination. On launch, the app compares its cached `schemaVersion` against the value returned from a lightweight `/content-version` endpoint. If stale, it downloads the updated pack in the background.

```
Client                         Server
  |                              |
  |  GET /content-version        |
  |  {"version": "1.2.0"}  <--  |
  |                              |
  | if cached != "1.2.0":        |
  |  GET /city-pack/Athens.json  |
  |  { CityPack }          <--  |
  |  cache locally               |
```

---

## Future offline city packs

A city pack is a static JSON file assembled from all available seed content for a destination. It can be:

- Bundled into the iOS app at release time (for the supported city list)
- Served from a CDN as a versioned static asset (`/packs/athens-1.2.0.json`)
- Downloaded on demand when a user selects a new destination

Pack generation is already possible: `buildCityPack("Athens")` returns a valid `CityPack`. The missing pieces are:

1. A build script that serialises packs to `public/packs/[destination].json`
2. An iOS download + caching layer
3. A `/content-version` endpoint that the iOS client can poll cheaply

---

## iOS parity plan

The iOS app currently calls the backend live for itinerary generation and reads contextual content directly from Swift code. The target state:

| Feature | Current iOS | Target iOS |
| --- | --- | --- |
| Contextual tips | Not yet | Bundled `CityPack` JSON |
| History & Mythology | Not yet | Bundled `CityPack` JSON |
| Saved itineraries | SwiftData local | Supabase sync (user-scoped) |
| Journal entries | Not yet | Supabase sync (user-scoped) |
| Itinerary generation | Backend API | No change (requires network) |

The `StructuredItinerary` type in `web/types/saved-itinerary.ts` is the canonical portable itinerary format. iOS should parse this from the `structured_itinerary_json` column rather than re-parsing `raw_response`. This decouples iOS rendering from backend contract evolution.

---

## What not to implement yet

- Service Workers / Cache API (web)
- IndexedDB for offline writes (web)
- Background sync or conflict resolution
- Realtime subscriptions

These are premature until the sync boundary design is validated with real usage. The types and content structure are ready for them; the implementation is deferred.
