# CityScout — iOS Sync Readiness Strategy

This document describes how CityScout's current data contracts are structured for future iOS/web synchronisation. No real-time sync exists today. This is a readiness guide, not an active implementation.

---

## Current sync boundary

| Layer | Source of truth | Sync needed? |
|---|---|---|
| Saved itineraries | Supabase (user-owned) | Yes — user wants these on iOS |
| Journal entries | Supabase (user-owned) | Yes — core trip companion data |
| Local intelligence | Static seed (web-bundled) | No — replicate seed to iOS bundle |
| History & mythology | Static seed (web-bundled) | No — replicate seed to iOS bundle |
| Walking narratives | Static seed (web-bundled) | No — replicate seed to iOS bundle |
| CityPack bundles | Assembled at request time | Export on demand |
| Auth session | Supabase Auth | Shared via Supabase token |

---

## Ownership rules

- **User-generated data** (itineraries, journal) is owned by the authenticated Supabase user and lives in Postgres. Either surface can write; the last write wins.
- **Seed content** (intelligence, history, narratives) is owned by the app and versioned via `CITYSCOUT_CONTENT_VERSION`. No merge conflicts possible; just replace on version bump.
- **Auth** is handled by Supabase. Both iOS and web share the same auth tenant. Deep link `?next=` redirect on sign-in handles web; Supabase OAuth deep links handle iOS.

---

## Data structure audit

### Saved itineraries

```typescript
// web/types/saved-itinerary.ts
interface SavedItineraryRow {
  id: string;           // UUID — stable, sync-safe
  destination: string;
  title: string;
  summary: string | null;
  created_at: string;   // ISO 8601
  updated_at: string;   // ISO 8601
}

interface SavedItineraryFull extends SavedItineraryRow {
  raw_response: PlanItineraryResponse;          // backend contract snapshot
  structured_itinerary_json: StructuredItinerary | null; // normalised display format
}
```

Swift Codable notes:
- All fields map directly to Swift primitives
- `id`, `created_at`, `updated_at` → `String` or `UUID`/`Date` with custom decoder
- `structured_itinerary_json` → `StructuredItinerary?` (Codable struct)
- `raw_response` is informational; iOS should consume `structured_itinerary_json`

### StructuredItinerary (canonical display format)

```typescript
interface StructuredItinerary {
  destination: string;
  title: string;
  summary: string | null;
  stops: StructuredStop[];
  notes: string[];
}

interface StructuredStop {
  id: string;         // deterministic slug — stable within a generation
  name: string;
  timeLabel: string;
  category: string;
  description: string;
  mapped: boolean;
}
```

Swift Codable notes:
- Maps directly with `@CodingKey` for camelCase ↔ snake_case if needed (all fields are already camelCase)
- `StructuredStop.id` is a deterministic slug, not a UUID — stable for a given generation but not globally unique across all generations
- Treat `mapped` as a display hint; coordinate data lives in `raw_response.stops[].latitude/longitude`

### Journal entries

```typescript
interface JournalEntry {
  id: string;           // UUID — stable, sync-safe
  user_id: string;      // UUID
  itinerary_id: string; // UUID — foreign key
  destination: string;
  title: string | null;
  body: string;
  mood: JournalMood | null;  // enum string
  created_at: string;
  updated_at: string;
}

type JournalMood = "reflective" | "adventurous" | "relaxed" | "energetic" | "romantic" | "overwhelmed";
```

Swift Codable notes:
- `JournalMood` maps to a Swift `enum` with `String` raw value and `CodingKey`
- Add `case unknown` with fallback decode so unknown future moods don't crash older iOS builds
- `title` and `mood` are optional — use `String?` and `JournalMood?`

### Seed content (local intelligence, history, walking narratives)

Seed types (`DestinationIntelligence`, `PlaceHistoryMythology`, `WalkingNarrative`) are serialisation-safe but **not per-item identified** — tips and stories have no UUID. This is intentional: seed content is versioned as a unit via `CITYSCOUT_CONTENT_VERSION`. When the version bumps, iOS replaces the whole bundle; no per-item merge is needed.

Do not add UUIDs to seed items unless per-item delta sync becomes a requirement.

---

## Versionability

| Structure | Version mechanism |
|---|---|
| Seed content | `CITYSCOUT_CONTENT_VERSION` constant in `web/types/offline.ts` |
| Local intelligence seed | `LOCAL_INTELLIGENCE_SEED_VERSION` in `web/lib/local-intelligence/seed.ts` |
| History/mythology seed | `HISTORY_MYTHOLOGY_SEED_VERSION` in `web/lib/history-mythology/seed.ts` |
| Walking narratives seed | `WALKING_NARRATIVES_SEED_VERSION` in `web/lib/walking-narratives/seed.ts` |
| CityPack bundle | `schemaVersion` field on the `CityPack` struct |
| Supabase schema | Migration SQL in `web/supabase/schema.sql` and `journal-schema.sql` |

iOS should compare the server-returned `schemaVersion` against its bundled version on launch. If they differ, re-fetch seed content.

---

## Conflict handling strategy

Today there is no multi-device write conflict resolution. The strategy at this stage:

**Saved itineraries:** Last-write-wins via `updated_at`. The web surface generates new itineraries but does not edit them after saving. iOS, once it supports saving, would follow the same pattern.

**Journal entries:** Last-write-wins via `updated_at`. Supabase's UPDATE RLS policy enforces that only the owner can write. If two devices write simultaneously, one will overwrite the other — acceptable given the personal, diary-like nature of journal entries.

**Seed content:** No conflict possible — read-only, versioned globally.

---

## Offline-first assumptions

1. **Saved itineraries** can be fully displayed offline once fetched — all display data lives in `structured_itinerary_json`.
2. **Journal entries** can be read offline once fetched. Writes should queue locally and sync when connectivity returns (not implemented yet).
3. **Seed content** should be bundled into the iOS app binary for day-one offline use, with background refresh on launch if the version has changed.
4. **CityPack** is the portable offline bundle — call `buildCityPack()` in `web/lib/city-pack.ts` to assemble one for a destination. The resulting JSON is the format iOS would cache.

---

## Eventual background sync model (future)

When iOS sync is implemented, the recommended approach:

1. **On launch:** Compare local `CITYSCOUT_CONTENT_VERSION` with a lightweight `/api/content-version` endpoint. If stale, fetch updated seed bundle in background.
2. **On foreground:** Fetch delta for saved itineraries and journal entries since last `updated_at`. Upsert locally.
3. **On write:** Optimistic local update → Supabase write → reconcile on next sync cycle.
4. **On conflict:** Keep the row with the later `updated_at`. Display a subtle "updated on another device" indicator.

---

## Local cache strategy (future)

- **SwiftData** is the natural persistence layer given CityScout's existing iOS stack.
- Each `SavedItinerary` and `JournalEntry` should be a `@Model` that mirrors the Supabase row schema.
- Seed content (`CityPack`) should be stored as a JSON blob in the app container, keyed by destination + schema version.
- Supabase Realtime subscriptions can be added later for live journal updates without polling.

---

## Web export helpers

`web/lib/city-pack.ts` exposes `buildCityPack(destination, options?)` which assembles a `CityPack` — the canonical offline-portable bundle. This function is already safe to call server-side and the result is directly serialisable to JSON.

No additional DTO transformers are needed today. The existing TypeScript types map cleanly to Swift `Codable` structs with minimal adaptation:
- camelCase field names are already Codable-compatible with `JSONDecoder().keyDecodingStrategy = .convertFromSnakeCase` for DB rows
- Union types (enums) map to Swift enums with `String` raw values
- Optional fields (`T | null`) map to `T?`

---

## What to do when iOS sync work begins

1. Add a `/api/content-version` route that returns `{ version: CITYSCOUT_CONTENT_VERSION }` — no auth needed.
2. Add a `/api/city-pack/:destination` route that returns a `CityPack` JSON — no auth needed (seed data only).
3. Use the Supabase JS/Swift SDK directly on iOS for saved itineraries and journal entries — no web proxy needed.
4. Enforce the same RLS policies (already in place) — iOS uses the user's Supabase JWT.
5. Consider adding a `sync_cursor` field (last sync timestamp) to the iOS local DB for efficient delta fetches.
