# CityScout — Itinerary Schema

This document describes the canonical itinerary data format used across CityScout's web layer, Supabase storage, CityPack offline bundles, and future iOS sync.

---

## Canonical format: `StructuredItinerary`

Defined in `web/types/saved-itinerary.ts`. This is the single authoritative format for itinerary display, saving, reopening, and offline export.

```typescript
interface StructuredItinerary {
  schemaVersion?: string;    // "1.0.0" — absent on rows saved before versioning
  destination: string;
  title: string;
  summary: string | null;
  stops: StructuredStop[];
  notes: string[];
}

interface StructuredStop {
  id: string;       // deterministic slug within a generation (e.g. "morning-0-1")
  name: string;
  timeLabel: string; // "Morning", "Afternoon", "Evening", or custom label
  category: string;
  description: string;
  mapped: boolean;  // true when backend matched to a geo POI
}
```

---

## Schema version

The constant `STRUCTURED_ITINERARY_VERSION` in `web/types/saved-itinerary.ts` tracks the current schema version. Bump this string when the shape changes in a way that affects rendering.

Rules:
- Increment the **patch** (e.g. `1.0.0 → 1.0.1`) for additive optional fields.
- Increment the **minor** (e.g. `1.0.0 → 1.1.0`) for renamed required fields or structural changes that require a migration helper.
- Increment the **major** (e.g. `1.0.0 → 2.0.0`) for breaking changes that require re-generation.

Old rows in Supabase will have `schemaVersion: undefined`. Treat this as `"0.x"` — legacy rows are still renderable; they simply predate versioning.

---

## Backend contract vs canonical format

The backend returns `PlanItineraryResponse` (defined in `web/types/itinerary.ts`), which is the raw API contract:

```typescript
interface PlanItineraryResponse {
  request_id?: string;
  destination: string;
  generated_at?: string;
  title?: string;
  summary?: string;
  stops?: ItineraryStop[];           // new format
  unmatched_stops?: ItineraryStop[];
  morning: ItineraryBlock;           // legacy format — do not remove
  afternoon: ItineraryBlock;
  evening: ItineraryBlock;
  notes: string[];
}
```

The web layer normalises this into `StructuredItinerary` via `buildStructuredItinerary()` in `web/app/actions/itineraries.ts` before persisting to Supabase. The raw response is also preserved in `raw_response` for debugging and re-normalisation.

**Important:** The legacy `morning`/`afternoon`/`evening` blocks must not be removed from `PlanItineraryResponse` until the iOS app is confirmed migrated to the new stops format.

---

## Storage

In Supabase, each `saved_itineraries` row stores:

| Column | Type | Contents |
|---|---|---|
| `raw_response` | `jsonb` | Full `PlanItineraryResponse` as returned by the backend |
| `structured_itinerary_json` | `jsonb` | Normalised `StructuredItinerary` for display and offline use |

Always read `structured_itinerary_json` for display. Use `raw_response` only to re-derive data or debug.

---

## Offline / CityPack

`StructuredItinerary` is included in `CityPack` (see `web/types/offline.ts`) under `structuredItinerary`. The `CityPack` itself has its own `schemaVersion` field (`CITYSCOUT_CONTENT_VERSION`) which covers the bundle as a whole.

```typescript
interface CityPack {
  schemaVersion: string;            // CITYSCOUT_CONTENT_VERSION
  structuredItinerary: StructuredItinerary | null;
  // ...other layers
}
```

---

## Removed types

`DraftItinerary` and `DraftItineraryStop` (previously in `web/types/itinerary.ts`) have been removed. They were structurally equivalent to `StructuredItinerary`/`StructuredStop` and only used in `lib/mock-itinerary.ts`, which now uses the canonical types directly.

---

## Migration notes for existing saved rows

Rows saved before `STRUCTURED_ITINERARY_VERSION` was introduced will have `schemaVersion: undefined` in `structured_itinerary_json`. No migration is required for rendering — all required fields are present. The `schemaVersion` field is optional in the type.

If a future schema change requires migrating old rows, run a Supabase SQL update against `structured_itinerary_json` using the `raw_response` column as the source of truth.

---

## Adding fields

To add a field to `StructuredItinerary`:

1. Add it as an optional field (`fieldName?: type`) to the interface.
2. Populate it in `buildStructuredItinerary()` in `web/app/actions/itineraries.ts`.
3. Bump `STRUCTURED_ITINERARY_VERSION` patch version.
4. Update `lib/mock-itinerary.ts` to include the field in test data.
5. Update this document.
