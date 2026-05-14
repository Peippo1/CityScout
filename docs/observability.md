# CityScout — Observability

Lightweight, provider-agnostic structured logging for the CityScout web layer. No external services, no agents, no paid tooling required.

---

## Philosophy

The web layer emits structured JSON log lines to stdout/stderr. Vercel ingests these automatically and makes them searchable in the dashboard. Any provider that captures stdout (Render, Fly.io, Railway, self-hosted) works identically.

The goal is enough signal to understand usage patterns, detect abuse, and diagnose failures — not comprehensive tracing.

---

## Log format

Every log line is a single JSON object on stdout or stderr. Fields:

| Field | Type | Always present | Notes |
| --- | --- | --- | --- |
| `ts` | ISO 8601 string | Yes | UTC timestamp |
| `level` | `info` \| `warn` \| `error` | Yes | Routing: info→stdout, warn→stderr, error→stderr |
| `route` | string | Yes | Route path or action name |
| `event` | string | Yes | What happened |
| `requestId` | string | When available | Propagated from `X-Request-Id` header |
| `durationMs` | number | When timed | Handler wall-clock time |
| `status` | number | When applicable | HTTP status returned to client |
| `destination` | string | When applicable | City name — safe to log |
| `clientHash` | string | When applicable | Truncated SHA-256 of client IP (16 hex chars) |
| `error` | string | On error paths | Safe error description only |

Example line:
```json
{"ts":"2026-05-14T23:00:00.000Z","level":"info","route":"/api/plan-itinerary","event":"generation_complete","requestId":"abc-123","status":200,"destination":"Athens","durationMs":1842}
```

---

## Instrumented events

| Route / Action | Event | Level | Notes |
| --- | --- | --- | --- |
| `POST /api/plan-itinerary` | `rate_limited` | warn | Includes `clientHash` and `durationMs` |
| `POST /api/plan-itinerary` | `generation_complete` | info | Success path; includes `destination` |
| `POST /api/plan-itinerary` | `upstream_error` | warn | Non-2xx from backend |
| `GET /auth/callback` | `auth_callback_success` | info | Session established |
| `GET /auth/callback` | `auth_callback_failed` | error | Code exchange failed |
| `saveItinerary` (Server Action) | `save_complete` | info | Includes `destination` |
| `saveItinerary` (Server Action) | `save_failed` | error | DB error description only |
| `deleteItinerary` (Server Action) | `delete_complete` | info | |
| `deleteItinerary` (Server Action) | `delete_failed` | error | DB error description only |

---

## IP anonymisation

Client IPs are never logged in plain text. The `clientHash` field contains a 16-character truncated SHA-256 hex digest of the IP string. This is sufficient to:
- Correlate multiple requests from the same client
- Detect unusual volume patterns
- Not be reversed to reveal the original IP

For stronger anonymisation in a regulated environment, replace `hashIp()` in `web/lib/logger.ts` with an HMAC-SHA-256 keyed by a rotating server-side secret stored as an environment variable.

---

## What is never logged

- Raw user text (itinerary prompts, journal entry bodies, notes)
- Supabase tokens or session cookies
- Environment variable values (API keys, secrets)
- Full stack traces (only `error.message` is logged)
- Raw IP addresses

---

## Searching logs

**Vercel dashboard:**
- Go to Logs → filter by `level:error` to see all error events
- Search for a `requestId` to trace a specific request end-to-end
- Filter by `event:rate_limited` to see abuse patterns

**CLI (local dev):**
```bash
npm run dev 2>&1 | grep '"level":"error"' | jq .
```

**Grep for a specific request:**
```bash
grep '"requestId":"abc-123"' vercel-logs.jsonl | jq .
```

---

## Logger utility (`web/lib/logger.ts`)

Three exports:
- `log(fields: LogFields)` — emit a structured log line
- `hashIp(ip: string): Promise<string>` — anonymise a client IP
- `startTimer(): () => number` — monotonic timer for duration measurement

Usage:
```typescript
import { log, hashIp, startTimer } from "@/lib/logger";

const elapsed = startTimer();
// ... do work ...
log({
  level: "info",
  route: "/api/plan-itinerary",
  event: "generation_complete",
  requestId,
  status: 200,
  destination: normalised.destination,
  durationMs: elapsed()
});
```

---

## Future improvements

- Add `log` calls to the guide message route (`/api/guide/message`)
- Add a request-scoped correlation ID that ties together multiple log lines (e.g. the proxy call + the backend response)
- Add `p50`/`p95` latency tracking via a lightweight in-memory histogram exported to `/health`
- Structured error reporting to Sentry or similar once the user base grows
