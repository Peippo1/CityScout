# CityScout Repository Review

Scope: senior-level review of repository structure, security, deployment readiness, maintainability, API consistency, tracing, and test coverage across `CityScout/`, `backend/`, `web/`, and `docs/`.

## Executive Summary

CityScout has a solid architectural direction:

- OpenAI usage stays server-side.
- The web app proxies through Next.js route handlers rather than calling the backend directly.
- The backend already has request IDs, security headers, validation, and tests.
- The iOS app keeps app secrets out of SwiftUI views and centralizes network config.

The main deployment risks are operational, not structural:

- public web proxy routes can trigger backend AI calls without any web-layer abuse control
- backend rate limiting is in-memory and IP-based, which is not strong enough for Render
- iOS release/device backend configuration is still incomplete
- OpenAI failure paths currently return mocked 200 responses, which hides outages

## Critical

No critical issue rises to the level of an immediate security compromise in the current repository state. The highest risks are in the `High` section.

## High

### 1. Public web proxy routes are unauthenticated and unthrottled

Files:

- [`web/app/api/plan-itinerary/route.ts`](/Users/tim/development/products/CityScout/web/app/api/plan-itinerary/route.ts)
- [`web/app/api/guide/message/route.ts`](/Users/tim/development/products/CityScout/web/app/api/guide/message/route.ts)
- [`web/app/api/_lib/proxy.ts`](/Users/tim/development/products/CityScout/web/app/api/_lib/proxy.ts)

Behavior:

- both route handlers accept any POST request
- neither route checks a session, token, origin, or user identity
- both immediately proxy to the backend using server-only env vars
- the proxy layer only validates env configuration and forwards the request

Why this matters:

- on Vercel, these endpoints are public by default
- anyone can trigger backend AI calls through the web surface
- the backend limiter is the only abuse control, and it is already weak
- this creates cost and scraping risk even though secrets stay server-side

Recommended fix:

- add a web-layer abuse control before proxying, even if the product stays anonymous
- choose one of:
  - short-lived anonymous session token
  - signed request token from the web server
  - basic user auth if persistence/sharing is part of the launch
- add per-route quotas and separate budgets for itinerary vs guide requests
- log and throttle by route + session + IP, not only IP

### 2. Backend rate limiting is in-memory and IP-based

Files:

- [`backend/app/core/security.py`](/Users/tim/development/products/CityScout/backend/app/core/security.py)
- [`backend/app/main.py`](/Users/tim/development/products/CityScout/backend/app/main.py)

Behavior:

- `InMemoryRateLimiter` stores counters in process memory
- `enforce_rate_limit()` keys requests by `request.client.host`
- no durable storage or distributed coordination is used
- the limiter resets on process restart and does not share state across instances

Why this matters:

- Render deployments often restart or scale horizontally
- in-memory state makes quotas easy to bypass after a restart
- `request.client.host` may reflect the proxy rather than the real caller unless forwarded headers are handled deliberately
- if the backend sits behind a platform proxy, the limiter can become either ineffective or overly broad

Recommended fix:

- move rate limiting to a shared store such as Redis/Upstash or a platform-native limiter
- key limits by route and a stable client/session identity, not just IP
- if IP is still used, resolve it from trusted forwarded headers only
- configure separate ceilings for `/plan-itinerary` and `/guide/message`

### 3. iOS release/device backend configuration is incomplete

Files:

- [`CityScout/Core/Config/AppEnvironment.swift`](/Users/tim/development/products/CityScout/CityScout/Core/Config/AppEnvironment.swift)
- [`CityScout/Services/PlanAPIService.swift`](/Users/tim/development/products/CityScout/CityScout/Services/PlanAPIService.swift)
- [`CityScout/Services/GuideAPIService.swift`](/Users/tim/development/products/CityScout/CityScout/Services/GuideAPIService.swift)
- [`CityScout.xcodeproj/project.pbxproj`](/Users/tim/development/products/CityScout/CityScout.xcodeproj/project.pbxproj)

Behavior:

- debug simulator defaults to `http://127.0.0.1:8000`
- release build settings leave `CITYSCOUT_API_BASE_URL` and `CITYSCOUT_DEVICE_API_BASE_URL` empty
- `PlanAPIService` and `GuideAPIService` fail when the base URL is empty

Why this matters:

- the simulator path works locally, but physical devices do not reach `127.0.0.1` on the host Mac
- TestFlight or device testing will fail until a device-reachable backend URL is configured
- the repo already calls this out in docs, but the project configuration is still not deployment-ready

Recommended fix:

- set a device-safe backend base URL for release/TestFlight builds
- document the exact build-setting and/or environment strategy in `README.md` or `docs/`
- keep the shared secret out of source control and provide it via Xcode scheme, xcconfig, or CI secrets

### 4. OpenAI failures return mocked 200 responses

Files:

- [`backend/app/services/itinerary_service.py`](/Users/tim/development/products/CityScout/backend/app/services/itinerary_service.py)
- [`backend/app/services/guide_service.py`](/Users/tim/development/products/CityScout/backend/app/services/guide_service.py)

Behavior:

- if OpenAI is unavailable, times out, or returns bad content, the service returns fallback content
- the HTTP status remains `200`
- the fallback content explicitly describes itself as mocked in the itinerary path

Why this matters:

- outages are hidden from clients and monitoring
- logs will show an internal failure, but the API still looks successful
- users may receive fabricated content without any explicit error boundary
- this makes incident detection and cost analysis harder

Recommended fix:

- return a structured non-2xx error for production failures
- keep the fallback path only for local/dev/test or an explicit feature flag
- if a fallback is intentionally retained, mark it clearly in the response schema and UI

## Medium

### 5. Request ID tracing is only partial

Files:

- [`backend/app/routes/itinerary.py`](/Users/tim/development/products/CityScout/backend/app/routes/itinerary.py)
- [`backend/app/routes/guide.py`](/Users/tim/development/products/CityScout/backend/app/routes/guide.py)
- [`backend/app/services/itinerary_service.py`](/Users/tim/development/products/CityScout/backend/app/services/itinerary_service.py)
- [`backend/app/services/guide_service.py`](/Users/tim/development/products/CityScout/backend/app/services/guide_service.py)

Behavior:

- responses carry `request_id`
- backend errors also carry `request_id`
- request handlers log destination and counts, but not the request ID on successful paths
- OpenAI status errors log the upstream request ID, but not always the CityScout request ID in the same log line

Why this matters:

- tracing works best when the same identifier is present in every hop
- without request ID in success logs, debugging multi-hop issues is slower
- cost and latency analysis become harder to correlate across frontend, backend, and upstream model calls

Recommended fix:

- include `request_id` in all backend request logs
- propagate `request_id` into all structured error logs
- keep the same ID in the Next.js proxy logs if you add server logging there

### 6. API contract documentation and implementation are out of sync

Files:

- [`docs/ARCHITECTURE.md`](/Users/tim/development/products/CityScout/docs/ARCHITECTURE.md)
- [`docs/API_CONTRACT.md`](/Users/tim/development/products/CityScout/docs/API_CONTRACT.md)
- [`backend/app/schemas/itinerary.py`](/Users/tim/development/products/CityScout/backend/app/schemas/itinerary.py)
- [`backend/app/schemas/guide.py`](/Users/tim/development/products/CityScout/backend/app/schemas/guide.py)

Behavior:

- the backend currently serves the legacy day-part itinerary shape
- the docs describe a proposed canonical V1 contract with `stops`, `generated_at`, `title`, and `summary`
- [`docs/ARCHITECTURE.md`](/Users/tim/development/products/CityScout/docs/ARCHITECTURE.md) still lists only `GET /health` and `POST /plan-itinerary` under backend role, even though `/guide/message` now exists
- the health response in code includes `request_id`, while the contract docs still show `{ "status": "ok" }`

Why this matters:

- consumers can implement against different assumptions
- the web layer already has optional types for future fields, so drift is easy to miss
- deployment readiness depends on a contract that is explicit and versioned

Recommended fix:

- update docs to reflect current behavior and the migration state
- add contract tests around the canonical response fields
- if the new itinerary schema is still future-state, version it explicitly rather than relying on optional fields

### 7. Dependency and version drift is still high

Files:

- [`web/package.json`](/Users/tim/development/products/CityScout/web/package.json)
- [`backend/requirements.txt`](/Users/tim/development/products/CityScout/backend/requirements.txt)
- [`.github/workflows/ci.yml`](/Users/tim/development/products/CityScout/.github/workflows/ci.yml)

Behavior:

- web depends on `next@16.3.0-canary.6`
- backend Python dependencies are unpinned in `requirements.txt`
- CI uses `npm install`, not `npm ci`

Why this matters:

- canary framework versions are harder to trust in production
- unpinned Python dependencies can drift under the same source tree
- `npm install` can mutate lockfiles and is less reproducible than `npm ci`

Recommended fix:

- pin production dependencies where practical
- add a constraints file or lock strategy for Python if you want deterministic backend installs
- switch web CI to `npm ci`
- avoid canary Next.js in the production deploy path unless there is a strong reason to keep it

### 8. Web test coverage is incomplete for the full proxy surface

Files:

- [`web/tests/routes/plan-itinerary-route.test.ts`](/Users/tim/development/products/CityScout/web/tests/routes/plan-itinerary-route.test.ts)
- [`web/app/api/guide/message/route.ts`](/Users/tim/development/products/CityScout/web/app/api/guide/message/route.ts)

Behavior:

- the web test suite covers `/api/plan-itinerary`
- there is no direct route test for `/api/guide/message`
- the proxy helper is heavily tested through the plan route, but guide behavior is still a gap

Why this matters:

- the guide route is part of the deployed public surface
- route-specific regressions will not be caught until manual testing or end-to-end smoke

Recommended fix:

- add route tests for `/api/guide/message`
- assert request ID propagation and backend proxy behavior there too

### 9. Render and Vercel deployment manifests are not present in-repo

Files:

- repository root

Behavior:

- there is no `render.yaml`, `vercel.json`, or equivalent repo-managed deployment descriptor
- deployment assumptions are documented, but the actual platform config lives outside the repository

Why this matters:

- deploy settings can drift from code and docs
- environment variable names, build commands, and start commands are easier to review when they are versioned

Recommended fix:

- add deployment manifests if you want config-as-code
- at minimum, document the exact Render and Vercel env vars and build commands in one place

## Low

### 10. Backend CORS headers are narrower than the proxy surface

Files:

- [`backend/app/main.py`](/Users/tim/development/products/CityScout/backend/app/main.py)

Behavior:

- CORS allow headers include `Content-Type` and `X-CityScout-App-Secret`
- `X-Request-Id` is not listed

Why this matters:

- it is fine for the current BFF architecture because the browser should not call the backend directly
- it becomes a friction point if the backend is ever exercised directly from a browser during debugging or future refactors

Recommended fix:

- if direct browser access is never intended, keep the backend private and leave this as-is
- if browser access is planned, add `X-Request-Id` and align CORS with the contract

### 11. Public-facing documentation is still partly stale

Files:

- [`docs/ARCHITECTURE.md`](/Users/tim/development/products/CityScout/docs/ARCHITECTURE.md)
- [`docs/PROJECT_CONTEXT.md`](/Users/tim/development/products/CityScout/docs/PROJECT_CONTEXT.md)
- [`README.md`](/Users/tim/development/products/CityScout/README.md)

Behavior:

- some docs describe the backend as itinerary-only or still in transition
- the web and guide surface now exist, but not every summary paragraph reflects that consistently

Why this matters:

- stale docs lead to wrong deployment assumptions and stale onboarding instructions

Recommended fix:

- align the high-level architecture docs with current endpoints and release readiness

## Nice-To-Have

### 12. Add stronger web security headers

Files:

- [`web/next.config.mjs`](/Users/tim/development/products/CityScout/web/next.config.mjs)

Suggested improvement:

- add a content security policy and other response headers at the Next.js layer
- especially useful once the web surface becomes public-facing

### 13. Add a generated client or formal OpenAPI export

Files:

- [`backend/app/schemas/itinerary.py`](/Users/tim/development/products/CityScout/backend/app/schemas/itinerary.py)
- [`backend/app/schemas/guide.py`](/Users/tim/development/products/CityScout/backend/app/schemas/guide.py)
- [`web/types/itinerary.ts`](/Users/tim/development/products/CityScout/web/types/itinerary.ts)
- [`web/types/guide.ts`](/Users/tim/development/products/CityScout/web/types/guide.ts)

Suggested improvement:

- publish a machine-readable contract and generate the web types from it
- this reduces drift between backend, web, and docs

### 14. Expand deployment observability

Files:

- [`backend/app/main.py`](/Users/tim/development/products/CityScout/backend/app/main.py)
- [`web/app/api/_lib/proxy.ts`](/Users/tim/development/products/CityScout/web/app/api/_lib/proxy.ts)

Suggested improvement:

- add structured logs for request ID, route, destination, duration, and upstream status
- add metrics for OpenAI success/failure, timeout, and fallback counts

## Immediate Fixes Before Deployment

1. Add web-layer abuse control before exposing the Vercel routes publicly.
2. Replace the backend in-memory rate limiter with a durable/shared limiter.
3. Configure a device-reachable backend URL for iOS release/TestFlight builds.
4. Stop returning mocked 200 responses for production OpenAI failures.
5. Pin or tighten dependency/version handling for web and backend installs.
6. Add a route test for `web/app/api/guide/message`.
7. Update the stale architecture and API docs so they match the current server behavior.

## Post-Deployment Hardening Roadmap

1. Introduce short-lived anonymous session tokens or lightweight auth for the web surface.
2. Add per-route quotas and cost budgets for itinerary vs guide calls.
3. Move rate limiting and abuse detection to durable infrastructure.
4. Version the itinerary contract explicitly before removing legacy shapes.
5. Add structured tracing across iOS, web proxy, backend, and OpenAI calls.
6. Add a CSP and security headers to the web app.
7. Consider generated API clients or a shared OpenAPI contract to reduce drift.
8. Revisit the iOS shared-secret compromise once device distribution and public usage increase.

## Verdict

CityScout is structurally well organized and already follows the right architectural boundaries for server-side AI.

The main gaps are not design mistakes, but production-hardening gaps:

- abuse control is not yet strong enough for public web traffic
- rate limiting is not yet durable enough for Render
- iOS release configuration is not yet ready for real devices
- fallback behavior hides upstream AI failures

Those should be addressed before treating the current web/backend stack as deployment-ready.
