# CityScout API Contract

## Purpose

This document defines the shared API contract between the native iOS app, the future web app, and the backend.

The immediate goal is to add a stable itinerary contract that both clients can consume without breaking the current iOS behavior.

Rules:
- OpenAI calls stay server-side.
- Clients talk only to the backend.
- Backend responses should be explicit, versionable, and easy to debug.
- Existing iOS behavior must remain valid during the transition.

## Current Backend Endpoints

### `GET /health`

Purpose:
- lightweight liveness check

Current response:
```json
{ "status": "ok" }
```

Status codes:
- `200` when the service is healthy

Notes:
- this endpoint is unauthenticated today
- keep the shape stable

### `POST /plan-itinerary`

Purpose:
- generate a one-day itinerary for a destination

Current request headers:
- `X-CityScout-App-Secret`
- `Content-Type: application/json`

Current request body:
```json
{
  "destination": "Paris",
  "prompt": "Plan me a relaxed day with coffee and art",
  "preferences": ["Relaxed", "Cafes", "Sightseeing"],
  "saved_places": ["Louvre Museum", "Cafe de Flore"]
}
```

Current behavior:
- validates the request body
- enforces the shared app secret
- applies in-memory rate limiting
- returns a day-part itinerary object used by the current iOS app

Current response shape, as implemented today:
```json
{
  "destination": "Paris",
  "morning": {
    "title": "Morning",
    "activities": ["..."]
  },
  "afternoon": {
    "title": "Afternoon",
    "activities": ["..."]
  },
  "evening": {
    "title": "Evening",
    "activities": ["..."]
  },
  "notes": ["..."]
}
```

Status codes:
- `200` on success
- `401` for missing or invalid shared secret
- `422` for validation errors
- `429` for rate limiting
- `500` for configuration or unexpected backend errors

### `POST /guide/message`

Purpose:
- return a travel guide style response for a destination question

Current request headers:
- `X-CityScout-App-Secret`
- `Content-Type: application/json`

Current request body:
```json
{
  "destination": "Paris",
  "message": "Give me a short walking tour",
  "context": []
}
```

Current response shape:
```json
{
  "destination": "Paris",
  "reply": "...",
  "suggested_prompts": [
    "What should I know about this city?",
    "Give me a short walking tour",
    "What food should I try?",
    "Tell me something interesting nearby"
  ]
}
```

Status codes:
- `200` on success
- `401` for missing or invalid shared secret
- `422` for validation errors
- `429` for rate limiting
- `500` for configuration or unexpected backend errors

## Proposed Stable V1 Itinerary Contract

This section defines the canonical itinerary contract for the shared product surface.

Important:
- this is the target contract for iOS and web
- current iOS behavior must not break during migration
- backend changes described below are proposed until implemented

### Migration Strategy

The backend should keep the current legacy day-part fields available while the new contract rolls out.

Recommended transition shape:
- keep `destination`, `morning`, `afternoon`, `evening`, and `notes` so the current iOS client continues to work
- add the new canonical fields listed below
- web should consume the new `stops` contract
- iOS can migrate at its own pace

If a future clean break is needed, do it behind a versioned endpoint or a clear response version gate. Do not silently remove the legacy fields.

### Proposed Request: `POST /plan-itinerary`

Request headers:
- `X-CityScout-App-Secret`
- `Content-Type: application/json`
- optional `X-Request-Id` from the client for trace correlation

Request body:
```json
{
  "destination": "Paris",
  "prompt": "Plan me a relaxed day with coffee and art",
  "preferences": ["Relaxed", "Cafes", "Sightseeing"],
  "saved_places": ["Louvre Museum", "Cafe de Flore"]
}
```

Request field rules:
- `destination` is required, trimmed, 1 to 80 characters
- `prompt` is required, trimmed, 1 to 1000 characters
- `preferences` is optional, trimmed string array, max 10 entries
- `saved_places` is optional, trimmed string array, max 25 entries

### Proposed Success Response

The canonical V1 response should include the fields below.

```json
{
  "request_id": "req_01JABCDEF1234567890",
  "destination": "Paris",
  "generated_at": "2026-04-30T12:34:56Z",
  "title": "A relaxed day in Paris",
  "summary": "Coffee, art, and an easy walking route through the city.",
  "stops": [
    {
      "id": "stop_01JABCDEF1234567890_01",
      "name": "Louvre Museum",
      "time_label": "Morning",
      "category": "museum",
      "description": "Start with the Louvre and nearby cafes before the crowds build.",
      "latitude": 48.8606,
      "longitude": 2.3376,
      "matched_poi_id": "poi_louvre_museum",
      "confidence": 0.96
    },
    {
      "id": "stop_01JABCDEF1234567890_02",
      "name": "Coffee stop near Saint-Germain",
      "time_label": "Morning",
      "category": "food",
      "description": "Take a slower coffee break before heading to the next area.",
      "latitude": null,
      "longitude": null,
      "matched_poi_id": null,
      "confidence": null
    }
  ],
  "unmatched_stops": [
    {
      "id": "stop_01JABCDEF1234567890_02",
      "name": "Coffee stop near Saint-Germain",
      "time_label": "Morning",
      "category": "food",
      "description": "Take a slower coffee break before heading to the next area.",
      "latitude": null,
      "longitude": null,
      "matched_poi_id": null,
      "confidence": null
    }
  ],
  "morning": {
    "title": "Morning",
    "activities": ["..."]
  },
  "afternoon": {
    "title": "Afternoon",
    "activities": ["..."]
  },
  "evening": {
    "title": "Evening",
    "activities": ["..."]
  },
  "notes": ["..."]
}
```

### Proposed Response Field Semantics

`request_id`
- required on every response, success or error
- unique per request
- should be returned in the JSON body and mirrored in an `X-Request-Id` response header
- may be generated by the backend or propagated from an inbound client request ID

`generated_at`
- ISO 8601 UTC timestamp
- generated by the backend when the itinerary is finalized

`title`
- short human-readable itinerary title
- suitable for cards, sharing, and page headings

`summary`
- one to three concise sentences
- should describe the overall plan, not every stop

`stops`
- canonical ordered itinerary list
- each stop represents one planned activity or anchor
- order is the itinerary order
- the list should be suitable for rendering on web and iOS

`id`
- stable unique identifier within the itinerary response
- must be present even when the stop cannot be matched to a POI

`name`
- display name for the stop
- can be a POI name, route anchor, or descriptive generated title

`time_label`
- human-readable time bucket
- examples: `Morning`, `Late Morning`, `Afternoon`, `Evening`, `Night`
- keep this stable enough for UI grouping

`category`
- a short classification used for UI styling and filtering
- examples: `museum`, `food`, `viewpoint`, `shopping`, `walk`, `nightlife`, `transport`, `rest`
- the backend should keep this list small and predictable

`description`
- concise stop description or instruction
- this is the text shown to the user

`latitude` and `longitude`
- nullable numbers
- use only when the backend has a reliable geographic match
- if either coordinate is unknown, both should usually be `null`

`matched_poi_id`
- nullable identifier for a known POI in the product data model
- `null` when the stop is generated text without a confident POI match

`confidence`
- nullable decimal score between `0.0` and `1.0`
- higher means a stronger match between the generated stop and a known POI
- `null` when the stop is unmatched or the confidence cannot be computed

`unmatched_stops`
- optional convenience array
- contains the subset of stops where `matched_poi_id` is `null`
- this is primarily for web UI treatment, debugging, and review flows
- the canonical source of truth remains `stops`

Legacy fields during transition:
- `destination`
- `morning`
- `afternoon`
- `evening`
- `notes`

These fields should remain available while the iOS client still depends on them.

### Unmatched Stop Handling

The contract must support generated stops that do not map to a known POI.

Rules:
- keep the stop in `stops`
- set `matched_poi_id` to `null`
- set `confidence` to `null`
- set `latitude` and `longitude` to `null` unless the backend has reliable coordinates
- if `unmatched_stops` is present, include the stop there as well

Client behavior:
- iOS and web should render unmatched stops as valid itinerary entries
- web may show them with a softer visual treatment or an "unmatched" badge
- do not drop unmatched stops from the response

### Proposed Error Shape

Errors should use a predictable JSON body with a stable `request_id`.

```json
{
  "error": {
    "code": "rate_limited",
    "message": "Rate limit exceeded.",
    "request_id": "req_01JABCDEF1234567890",
    "details": {
      "retry_after_seconds": 60
    }
  }
}
```

Required fields:
- `error.code`
- `error.message`
- `error.request_id`

Optional fields:
- `error.details`

Recommended error codes:
- `invalid_request`
- `unauthorized`
- `forbidden`
- `validation_error`
- `rate_limited`
- `upstream_unavailable`
- `internal_error`

Recommended HTTP status mapping:
- `400` for malformed requests
- `401` for missing or invalid shared secret
- `403` for authenticated but disallowed requests
- `422` for validation failures
- `429` for rate limiting
- `500` for internal failures

### Backward Compatibility Requirements

To avoid breaking the existing iOS app:
- the current response shape must remain valid until iOS is updated
- new fields should be additive
- legacy keys should not be removed without a migration window
- response parsing on clients should ignore unknown fields
- backend tests should cover both the legacy and the V1 shape during the transition period

## Shared Client Expectations

### iOS
- continues using the current `PlanAPIService` behavior until migrated
- should be able to ignore additional keys safely
- may later move to the new `stops` model for richer map and itinerary rendering

### Web
- should target the proposed V1 contract from day one
- should not depend on legacy `morning` / `afternoon` / `evening` blocks for core rendering
- should use `request_id` for debugging and support handoff into support or logs

### Backend
- should own request validation, AI orchestration, and error shaping
- should expose stable JSON contracts
- should remain the only place where OpenAI is called

## Implementation Notes

This document is intentionally prescriptive so implementation can start without redefining the contract later.

Recommended next steps:
- add backend tests for the proposed error envelope
- add backend tests for the proposed itinerary response shape
- keep the current iOS parser working during the migration window
- introduce a `request_id` in backend responses and logs
- update the web client to consume the stop-based response model
