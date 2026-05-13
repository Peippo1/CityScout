# CityScout — AI Agents and Services

This document catalogues the current AI-powered flows in CityScout, the principles that govern them, and planned future agents.

---

## Current agents and services

### 1. Itinerary generation

**Purpose:** Generate a one-day city itinerary tailored to a destination, travel style, and user notes.

**Flow:**
```
User (iOS / Web)
  → iOS PlanAPIService  OR  Web Next.js Route Handler (/api/plan-itinerary)
  → FastAPI /plan-itinerary
  → OpenAI chat completion (GPT-4 class model)
  → Structured itinerary response
  → iOS ItineraryPlaceMatcher (POI resolution)  OR  Web itinerary renderer
```

**Inputs:** destination, prompt, preferences[], saved_places[]  
**Outputs:** title, summary, stops[], morning/afternoon/evening blocks (legacy), notes[], request_id  
**Rate limit:** 20 requests / 10 minutes per client (enforced at both proxy and backend)  
**Timeout:** 20 seconds at the web proxy; backend handles its own upstream timeout  
**Error codes:** `rate_limited`, `upstream_unavailable`, `upstream_timeout`, `proxy_misconfigured`, `validation_error`

**Contract stability:** The `morning`/`afternoon`/`evening` legacy block format must remain in the response until the iOS client migrates to the `stops[]` model. See `docs/API_CONTRACT.md` for the full V1 migration plan.

---

### 2. Guide chat

**Purpose:** Answer destination-specific travel questions in a local-guide voice. Surfaces suggested follow-up prompts.

**Flow:**
```
User (iOS)
  → iOS GuideAPIService
  → FastAPI /guide/message
  → OpenAI chat completion
  → Reply + suggested_prompts[]
```

**Inputs:** destination, message, context[]  
**Outputs:** destination, reply, suggested_prompts[]  
**Rate limit:** Same backend rate limiter as itinerary  
**Context:** The `context[]` field allows multi-turn conversation to pass prior exchanges

**Web status:** The web proxy route (`/api/guide/message`) exists but is not yet wired to a visible UI. The backend contract is stable.

---

## Agent interaction principles

**All agents follow these rules:**

1. **AI stays server-side.** OpenAI API keys and prompt orchestration live in the FastAPI backend. They must never move into the iOS app, web client, or browser JavaScript.
2. **Request tracing.** Every backend response includes a `request_id`. The web proxy propagates this end-to-end via `X-Request-Id` headers. Use request IDs when debugging or escalating failures.
3. **Graceful degradation.** If an agent call fails, the client should show a friendly message and remain usable. Local-first behaviour on iOS must not depend on agent success.
4. **Input validation before AI.** Validate and sanitise inputs at the route handler (web) and FastAPI route (backend) before passing to OpenAI. Never send unvalidated user text directly to a model.
5. **Structured outputs.** Prefer structured JSON responses with predictable field names over free-form text. This makes client rendering, tracing, and contract evolution tractable.
6. **No PII in prompts.** Do not include user account details, saved personal data, or device identifiers in prompts sent to OpenAI.
7. **Prompt versioning.** When changing a system prompt that affects response shape, treat it as a contract change and update `docs/API_CONTRACT.md`.

---

## Guardrails

| Guardrail | Where enforced |
|---|---|
| OpenAI key never in client | Backend env vars only |
| Shared backend secret | Backend validates; web proxy injects from server env |
| Rate limiting | Backend (per-IP, in-memory) + web proxy (per-IP, in-memory) |
| Request body size limit | FastAPI middleware (hard limit) |
| Input length limits | Backend Pydantic validators + web route handler sanitisation |
| CORS scope | Backend `APP_ALLOWED_ORIGIN(S)` setting |
| Error envelope | JSON-only; no raw stack traces to clients |
| Timeout | 20 s web proxy timeout → 504; backend owns upstream timeout |

---

## Cost awareness

- OpenAI completions are the dominant cost driver. All model calls go through the backend — this is the single control point for model selection, token limits, and caching decisions.
- Rate limiting at both layers provides a cost floor per user session.
- When adding new agent calls, estimate token usage and set explicit `max_tokens` in the backend service.
- Do not fan out multiple parallel OpenAI calls per user request without explicit approval.
- Prefer a single well-structured prompt over chained calls where possible.

---

## Failure handling

| Failure | Expected behaviour |
|---|---|
| OpenAI API error | Backend returns 503 `upstream_unavailable`; proxy returns friendly message to client |
| OpenAI timeout | Backend returns 504 `upstream_timeout` |
| Rate limit exceeded | 429 `rate_limited` with retry guidance in the user message |
| Missing env vars | 500 `proxy_misconfigured`; admin must check deployment config |
| Validation error | 422 `validation_error` with field detail in `error.details` |
| Network failure (iOS) | Local-first flows continue; itinerary/guide shows an error state |

Clients must handle all failure cases without crashing or leaking technical details to the user.

---

## Observability

Current state:
- `request_id` is generated per request and returned in both the JSON body and `X-Request-Id` response header.
- Backend uses Python `logging` with `request_id` context on error logs.
- Web proxy writes technical errors to `console.error` with the request ID.
- iOS logs service errors at debug level.

Planned improvements:
- Structured backend log lines with destination, model, latency, and token count per completion call.
- Request ID surfaced in the web UI error state for user-reportable support handoff.
- Vercel log drain or lightweight backend log aggregation for production monitoring.

---

## Planned future agents

These are ideas for future development. None are committed to any timeline.

### Local recommendations agent
**Concept:** A context-aware agent that surfaces place recommendations based on current location, time of day, and saved preferences. Closer to a real-time guide than itinerary planning.  
**Key dependency:** Real location data from the iOS app; requires privacy-safe handling of coordinates.

### Budget-aware planner
**Concept:** An itinerary generation variant that factors in a daily budget. Weights activity and food recommendations by estimated cost tier.  
**Key dependency:** Cost-tier metadata on POIs; likely requires a structured POI enrichment step.

### Weather-aware itinerary agent
**Concept:** Adjusts itinerary suggestions based on a weather forecast for the destination and travel dates. Re-weights indoor/outdoor stops depending on conditions.  
**Key dependency:** A weather API integration. Must be clear about forecast accuracy limits to the user.

### Transit optimisation agent
**Concept:** Reorders itinerary stops to minimise travel time using public transit routing. Could suggest metro/bus options between stops.  
**Key dependency:** A transit data API (e.g. Google Maps Directions, OpenTripPlanner). Requires per-city coverage check.

### Multilingual travel assistant
**Concept:** A guide chat variant that responds in the user's preferred language. Could also surface localised phrases for the destination language.  
**Key dependency:** Language preference setting in the user profile; model selection appropriate for the target language.

---

## Adding a new agent

Before implementing a new agent:

1. Define the input/output contract in `docs/API_CONTRACT.md`.
2. Confirm that all AI logic stays in the FastAPI backend.
3. Add rate-limit and timeout handling from day one.
4. Write backend tests covering the success path, error paths, and rate limit.
5. Ensure the web/iOS client shows a friendly error if the agent fails.
6. Estimate token usage and confirm it is acceptable before merging.
