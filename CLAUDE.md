# CityScout — Engineering Instructions for Claude Code

This file is the primary engineering reference for Claude Code (and similar AI coding tools) working in this repository. Read it before making changes.

---

## Project overview

CityScout is a city-first travel product with three surfaces:

| Surface | Technology | Role |
|---|---|---|
| **iOS app** | SwiftUI, SwiftData | Primary in-trip companion. Local-first. |
| **FastAPI backend** | Python, FastAPI, OpenAI | Itinerary generation and guide chat. Holds all AI secrets. |
| **Next.js web app** | Next.js 16, TypeScript, TailwindCSS | Pre-trip planning layer. Proxies to backend. |

The iOS app is the primary product. The web app is the planning surface. The backend serves both.

---

## Repository structure

```text
CityScout/
├── CityScout/                # iOS SwiftUI app
│   ├── App/
│   ├── Core/
│   ├── Features/
│   ├── Models/
│   ├── Services/
│   └── Resources/SeedContent/
├── backend/                  # FastAPI backend
│   ├── app/
│   │   ├── core/
│   │   ├── routes/
│   │   ├── schemas/
│   │   └── services/
│   └── tests/
├── web/                      # Next.js planning layer
│   ├── app/
│   │   ├── api/              # Route handlers (proxy layer)
│   │   └── plan/
│   ├── components/
│   ├── lib/
│   ├── types/
│   └── tests/
├── docs/                     # Architecture and product docs
│   ├── API_CONTRACT.md
│   ├── ARCHITECTURE.md
│   ├── CONVENTIONS.md
│   └── ...
├── .ai/skills/               # Reusable AI skill documents
├── CLAUDE.md                 # This file
└── AGENTS.md                 # Agent and AI service catalogue
```

---

## Deployment architecture

```
Browser → Next.js Route Handler → FastAPI Backend → OpenAI
iOS App                        → FastAPI Backend → OpenAI
```

- The browser never calls OpenAI or the FastAPI backend directly.
- Next.js route handlers inject `X-CityScout-App-Secret` from a server-only env var.
- The backend applies its own shared-secret validation and rate limiting.
- Both env vars (`CITYSCOUT_API_BASE_URL`, `CITYSCOUT_APP_SHARED_SECRET`) must remain server-side only.

---

## Technology stack

**iOS:** Swift, SwiftUI, SwiftData, Apple Translation framework  
**Backend:** Python 3.11+, FastAPI, Pydantic, OpenAI SDK, pytest, bandit  
**Web:** Next.js 16 App Router, React 19, TypeScript 5, TailwindCSS 3, Vitest, Playwright  
**CI:** GitHub Actions — separate workflows for iOS and backend/web

---

## Engineering philosophy

- **Minimal safe changes.** Fix what is asked. Do not refactor surrounding code speculatively.
- **Preserve working deployments.** If tests pass and the build is clean, it works. Do not restructure without a clear reason.
- **Local-first for iOS.** Core app behaviour must work without a network connection. Backend calls are optional enhancements.
- **Destination-scoped data.** All queries, saves, and itineraries are scoped to a selected city. Never build cross-city queries for convenience.
- **Clarity over density.** Prefer readable, explicit code over clever abstractions. Three similar lines is better than a premature helper.
- **No half-finished changes.** Do not leave stubs, TODO markers, or half-wired features unless explicitly asked.

---

## Rules for modifying the codebase

### Universal
- Run `npm test && npm run build` (web) or `python -m pytest` (backend) before considering a task complete.
- Do not introduce new third-party dependencies without a clear reason and explicit approval.
- Do not add auth flows or database tables. None exist yet; this is intentional.
- Do not silently remove backward-compatible API fields. The iOS client and web client may be on different versions.
- Explain architectural tradeoffs in the PR description or in a comment, not inside `CLAUDE.md`.

### iOS
- Do not touch iOS unless the task explicitly requires it.
- Do not modify the bundle identifier.
- Do not use UIKit unless explicitly requested; SwiftUI-first.
- Avoid force unwraps. Avoid global state.
- Keep business logic in services, not in SwiftUI views.
- Do not compare SwiftData model instances inside `#Predicate`. Compare scalar IDs captured outside the closure.

### Backend
- All OpenAI calls stay in the backend. Never move AI logic into the iOS app or web client.
- Keep the shared-secret header (`X-CityScout-App-Secret`) validation in place.
- Maintain JSON-only error responses with the established error envelope: `{ "error": { "code", "message", "request_id" } }`.
- Rate-limit enforcement stays in the backend. The web proxy also has a lightweight in-memory limit — both must stay.
- Do not remove legacy response fields (`morning`, `afternoon`, `evening`, `notes`) until iOS is confirmed migrated.

### Web
- Never expose `CITYSCOUT_APP_SHARED_SECRET` or `CITYSCOUT_API_BASE_URL` to browser JavaScript.
- All backend calls go through `web/app/api/` route handlers, never from `web/lib/api.ts` directly to FastAPI.
- API errors shown to users must be friendly and non-technical. Technical detail goes to `console.error` only.
- Do not add paid third-party services or analytics without explicit approval.

---

## Testing expectations

### Backend
```bash
cd backend
python -m pytest          # all tests must pass
bandit -r app -x tests    # no high-severity findings
```

### Web
```bash
cd web
npm run lint              # no lint errors
npm test                  # all Vitest tests pass
npm run build             # production build must succeed
```

### iOS
```bash
xcodebuild -project CityScout.xcodeproj -scheme CityScout \
  -configuration Debug -sdk iphonesimulator \
  -destination "generic/platform=iOS Simulator" clean build
```

**Test coverage expectations:**
- New route handlers need at least: 405 rejection, validation error, success shape, and rate-limit tests.
- New React components need at least: render test, key interactive state tests.
- Do not mock the database in backend tests — use the test fixtures in `backend/tests/conftest.py`.

---

## Security expectations

- No secrets in browser JavaScript. No exceptions.
- No secrets committed to the repository. Check `.gitignore` before staging `.env` or `.env.local` files.
- Validate all user input at the route-handler boundary (web) and the FastAPI route boundary (backend).
- Keep CORS origins tightly scoped in the backend (`APP_ALLOWED_ORIGIN`/`APP_ALLOWED_ORIGINS`).
- Do not add endpoints that bypass the shared-secret check without documented justification.
- If adding a new public endpoint (e.g. a health check), ensure it leaks no internal state.
- Run `bandit -r app -x tests` on any backend change.

---

## API proxy rules

The web proxy layer (`web/app/api/_lib/proxy.ts`) has a strict contract:

1. Validate and sanitise input before forwarding (trim, length-limit, type-check).
2. Inject `X-CityScout-App-Secret` from `process.env.CITYSCOUT_APP_SHARED_SECRET` — server-side only.
3. Forward `X-Request-Id` for end-to-end tracing.
4. Apply the in-memory rate limiter (20 req / 10 min per client IP per path).
5. Return structured JSON errors on all failure paths — never let raw backend errors reach the browser.
6. Respect the 20-second backend timeout and map it to a `504` with `upstream_timeout` code.
7. Return `500` with `proxy_misconfigured` if env vars are absent — do not silently pass empty headers.

See [.ai/skills/proxy-security.md](.ai/skills/proxy-security.md) for the full checklist.

---

## Documentation expectations

- Do not create `CHANGELOG.md`, `TODO.md`, or planning documents unless explicitly asked.
- Do not rewrite existing docs speculatively. Update the relevant section and leave the rest.
- Keep inline comments short: explain the *why*, not the *what*.
- Do not add multi-paragraph docstrings. One clear line maximum.
- If you change the API contract, update `docs/API_CONTRACT.md`.
- If you change the architecture, update `docs/ARCHITECTURE.md` or `docs/WEB_APP_ARCHITECTURE.md`.

---

## UX philosophy

- Calm, premium, restrained. Avoid visual noise.
- Friendly error messages. Never show raw API codes or stack traces to users.
- Loading states should communicate progress without fake percentages.
- Forms should have sensible defaults that demonstrate the product immediately.
- Alpha/beta notices should be honest but not alarming.
- The web app is the planning surface — it should feel deliberate and editorial, not dashboard-like.

---

## Definition of done

A task is complete when:

- [ ] The stated scope is implemented and nothing beyond it.
- [ ] `npm test && npm run build` pass (web changes).
- [ ] `python -m pytest` passes (backend changes).
- [ ] No new lint warnings or type errors.
- [ ] No secrets committed or exposed to the browser.
- [ ] Backward-compatible API fields are preserved.
- [ ] The existing test baseline has not regressed.
- [ ] Any new user-facing error paths show friendly messages.
- [ ] The PR description explains what changed and why, including any tradeoffs.
