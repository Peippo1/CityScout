# CityScout Web Security Review

## Scope

This review covers the current backend shared-secret auth model as it applies to a browser-based web app.

Current backend behavior:
- requests to `/plan-itinerary` and `/guide/message` require `X-CityScout-App-Secret`
- the secret is validated server-side with a static comparison
- rate limiting is in-memory and keyed by client IP
- CORS is enabled for local dev/test origins and any explicitly configured allowed origins

The core issue is that the current model was designed for a trusted native client with a server-side secret, not for an untrusted browser where shipped secrets can be extracted.

## 1. Why The Existing iOS Shared-Secret Model May Not Be Appropriate For Public Web Clients

The iOS model works because the app can be treated as a distributed client with no sensitive secret embedded in a public JavaScript bundle.

That assumption does not hold for web:
- any secret shipped to the browser can be read by users, browser extensions, and automated tooling
- `NEXT_PUBLIC_*` variables are bundled into client-side JavaScript and are therefore public
- once a browser-visible secret exists, it no longer authenticates a user or a session, it only identifies the app build
- a leaked browser secret can be reused from anywhere, which makes it weak protection against abuse, scraping, or unauthorized API use
- a static shared secret also cannot distinguish a legitimate user from a malicious script running in the same browser context

For a public web client, the shared-secret pattern is at best an application identifier and at worst a false sense of security.

## 2. What Secrets Can And Cannot Be Exposed In `NEXT_PUBLIC_*`

Rule of thumb:
- anything in `NEXT_PUBLIC_*` must be treated as public
- if the value would be harmful when copied into a GitHub issue, browser console, curl command, or third-party script, do not expose it in `NEXT_PUBLIC_*`

Can be exposed in `NEXT_PUBLIC_*`:
- public map provider identifiers or public map tiles config
- analytics or monitoring IDs that are meant to be public
- non-sensitive feature flags
- public backend base URLs
- public app branding values
- public content identifiers that do not grant access

Cannot be exposed in `NEXT_PUBLIC_*`:
- `APP_SHARED_SECRET`
- OpenAI API keys
- service-to-service tokens
- admin credentials
- private session signing keys
- database credentials
- any token that grants privileged access to the backend or third-party services

Important distinction:
- a value exposed to the browser is not secret, even if it is used in a header
- browser-side code can only safely send public identifiers, user tokens, or short-lived session tokens issued by the backend

## 3. Recommended V1 Approach For Local Development

For local development, keep the workflow simple and low-friction:
- use a local Next.js web app
- use the backend directly in development
- allow local CORS origins such as `localhost:3000` and `127.0.0.1:3000`
- use a development-only backend secret or a dev-only bypass that never reaches production
- keep the shared secret out of the browser bundle

Recommended local pattern:
- Next.js server-side code or route handlers read a non-public backend secret from server-only environment variables
- browser UI talks to the Next.js server layer, not directly to the backend
- the Next.js server layer forwards authenticated requests to the backend

This preserves a realistic integration path without teaching the browser a production secret.

## 4. Recommended Production Approach

There are three realistic production paths for CityScout web, plus one later-stage option.

### Option A: Public Web Endpoint With Stricter Rate Limiting

Use a public backend endpoint, but do not rely on a shared secret as the primary protection.

Use when:
- the endpoint is intended for anonymous or lightly authenticated public traffic
- the web app needs direct browser access to backend APIs

Requirements:
- strong rate limiting by IP, session, and possibly device fingerprint
- origin checks are helpful but not sufficient by themselves
- abuse detection, request quotas, and bot mitigation become mandatory
- higher-cost AI routes should have tighter per-user and per-IP budgets

Tradeoff:
- simplest client architecture
- hardest to protect against scraping and cost abuse

### Option B: Backend-For-Frontend Route Handlers In Next.js

Make Next.js the browser-facing layer and keep backend credentials server-side.

Use when:
- the web app is a product surface, not a generic public API consumer
- you want to keep the backend API private from browsers

Requirements:
- Next.js route handlers or server actions call the backend
- server-only environment variables hold any privileged backend secret
- the browser never sees the backend shared secret or OpenAI credentials
- the Next.js layer can enforce its own session checks, per-route throttling, and request shaping

Tradeoff:
- best security posture for a web app that is not meant to expose backend internals
- adds an extra server hop
- more moving parts in deployment and observability

### Option C: Anonymous Session Token

Issue a short-lived anonymous session token from the backend or web server and require it for itinerary and guide requests.

Use when:
- you need anonymous access with some abuse resistance
- you do not want account sign-in yet

Requirements:
- token must be short-lived and server-issued
- token should be scoped to session, origin, and possibly route
- token should be revocable and rate-limited separately from any browser-visible static identifier

Tradeoff:
- stronger than a static shared secret
- still anonymous and therefore still abuse-prone at scale

### Option D: Account-Based Auth Later

Add user accounts, login, and possibly paid tiers once the web product needs durable identity.

Use when:
- planning, sharing, or saved itineraries need persistence across devices
- you need per-user quotas, billing, or abuse enforcement

Tradeoff:
- strongest long-term control model
- more product and implementation overhead
- usually unnecessary for the very first web prototype

### Recommendation

For CityScout V1 web:
- prefer Next.js backend-for-frontend route handlers
- keep the backend shared secret server-side only
- optionally add short-lived anonymous session tokens later if browser traffic needs finer-grained abuse control
- defer account-based auth until sharing or persistence requires it

## 5. Rate Limiting Implications

The current backend rate limiter is in-memory and keyed by client IP.

Implications for web:
- IP-only rate limiting is weak in shared networks, NAT, mobile carriers, and corporate environments
- browser traffic can come from many users behind one IP, causing false positives
- a malicious user can rotate IPs or run distributed traffic
- in-memory state does not survive process restarts or horizontal scaling

Recommended rate limiting stack for web:
- backend global IP limits
- backend per-route limits for expensive AI endpoints
- Next.js edge or server-side throttling for browser-originated traffic
- optional session-based limits if anonymous sessions are introduced
- separate budgets for `/plan-itinerary` and `/guide/message`

Operational note:
- guide chat and itinerary generation should not share the same budget if one path is materially more expensive
- rate-limit failures should return a structured error with `request_id`

## 6. CORS Implications

CORS is not auth.

Current dev/test CORS allowing localhost is correct for local development, but production web requires explicit origin control.

Recommended approach:
- only allow the exact web app origin(s) in production
- avoid wildcard origins
- avoid `allow_credentials=true` unless you actually use browser cookies or credentialed requests
- keep allowed headers minimal
- continue allowing local development origins only in dev/test

Important:
- a permissive CORS policy does not stop a browser secret from being stolen
- CORS only governs which browser contexts can read responses, not who can send requests

If using Next.js backend-for-frontend handlers:
- browser-to-Next.js traffic is same-origin or controlled by the web app domain
- Next.js-to-backend traffic can be server-to-server and does not require public browser CORS exposure for the backend

## 7. OpenAI Cost-Control Risks

Browser exposure increases the risk of unbounded AI spend.

Primary risks:
- automated refreshes or script-driven request loops
- users generating the same itinerary repeatedly
- public routes being probed by bots
- low-friction anonymous access with expensive model calls
- lack of caching for deterministic or repeatable outputs

Mitigations:
- never expose OpenAI keys to the browser
- keep AI calls server-side only
- add request quotas per route and per session/user
- use cheaper models where acceptable
- cache or de-duplicate itinerary generation where inputs are stable
- make regeneration explicit so clients do not spam the backend accidentally
- log `request_id`, route, destination, and cost-relevant metadata

If web launches publicly, cost controls should be designed as a first-class requirement, not added after traffic appears.

## 8. Recommended Next Implementation Step

Implement a Next.js backend-for-frontend layer for the web app.

Why this is the best next step:
- it keeps the backend shared secret off the browser
- it allows the web UI to ship without redesigning the backend into a public anonymous API
- it preserves room for later account auth or anonymous session tokens
- it keeps OpenAI and backend orchestration server-side

Concrete next step:
- create Next.js route handlers for itinerary and guide requests
- store backend secrets in server-only environment variables
- have the browser call those route handlers instead of calling the backend directly
- add server-side rate limiting and request logging around those routes
- keep the backend contract aligned with the current iOS client while the web layer evolves

## Decision Summary

Do not expose the current shared secret to the browser.

Use the shared secret only server-side.

For V1 web, prefer Next.js route handlers as a browser-facing facade over the shared backend.

If anonymous traffic grows, add short-lived session tokens and stronger rate limits before opening the backend directly to the public web.
