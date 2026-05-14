# CityScout — Walking Narratives

Walking Narratives are ordered, atmospheric stop sequences designed to be read while moving through a place. The goal is a thoughtful travel companion voice — intelligent, concise, and grounded in specific detail — not a Wikipedia summary.

---

## Current coverage

| Place | Stops | Duration |
| --- | --- | --- |
| Athens | 6 | 90 min |
| Acropolis | 5 | 60 min |
| Ancient Agora | 4 | 45 min |

---

## Content structure

```typescript
interface WalkingNarrative {
  place: string;           // canonical name for matching
  aliases?: string[];      // alternate spellings and forms
  title: string;           // short title shown in the UI
  intro: string;           // one sentence setting the scene
  durationMinutes: number; // approximate walking time
  stops: NarrativeStop[];
}

interface NarrativeStop {
  id: string;
  name: string;
  type: NarrativeStopType; // approach | landmark | viewpoint | history |
                           // mythology | architecture | transition
  passage: string;         // 2–4 atmospheric sentences
  lookFor?: string;        // optional observation prompt
}
```

---

## Writing style guide

**Do:**
- Ground observations in specific, observable details ("the ceiling still shows traces of dark blue paint with gold stars")
- Use the second person sparingly and naturally ("as you pass through")
- Choose one interesting angle per stop rather than covering everything
- End passages with a thought that earns the reader's next step

**Don't:**
- List dates and rulers without context
- Explain things the reader could see for themselves
- Use the word "incredible", "stunning", or "breathtaking"
- Write more than four sentences per passage

---

## Architecture

**Seed data:** `web/lib/walking-narratives/seed.ts`  
**Matcher:** `getWalkingNarrative(place)` — case-insensitive, alias-aware, returns `null` for unknown places  
**Component:** `WalkingNarrative` — renders stop list with type badge and optional "Look for" note; returns `null` when no narrative exists  
**Rendered:** at the bottom of the `GeneratedItinerary` component in `plan-workspace.tsx`, alongside Local Intelligence and History & Mythology

The walking narrative renders for the destination as a whole. Future versions could match individual stop names from the itinerary against narrative stop names to show contextual passages inline.

---

## Future extension points

**Audio guides:** Add an `audioUrl` field to `NarrativeStop`. The component can render a play button when the URL is present. No structural change needed.

**GPS-triggered passages:** Add `latitude` and `longitude` to `NarrativeStop`. A location-aware client (iOS) can trigger the passage when the user is within a radius, without changing the web rendering.

**Walking route maps:** The ordered stop list is already a route. Adding coordinates makes it directly usable as a GPX track or map overlay.

**Multilingual narratives:** Add `languageCode` to `WalkingNarrative` and store multiple narratives per place. The matcher can prefer the user's language with a fallback to English.

**Offline city packs:** `WalkingNarrative` is serialisation-safe. It fits naturally into the `CityPack` type (see `docs/offline-strategy.md`) as `walkingNarrative: WalkingNarrative | null`.

**AI-generated narratives:** Replace `getWalkingNarrative` with an async function that calls the CityScout backend for destinations not covered by seed data. The component interface stays identical.

---

## Adding a new narrative

1. Add an entry to `web/lib/walking-narratives/seed.ts`.
2. Bump `WALKING_NARRATIVES_SEED_VERSION` and `CITYSCOUT_CONTENT_VERSION`.
3. Run `npm test` — the seed integrity tests will catch missing fields.
4. No other changes required.
