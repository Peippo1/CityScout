# CityScout

CityScout is a city-first product built around three surfaces:
- a native iOS travel companion built with SwiftUI and SwiftData
- a FastAPI backend that handles itinerary generation and guide replies
- a Next.js web planning layer for pre-trip planning and sharing

The iOS app remains the primary in-trip experience. The web app is the planning surface, not a full duplicate of the native app.

## Product Surfaces

### iOS Native App
- Onboarding and destination selection
- Lessons, phrasebook, pronunciation practice, translate
- Explore, map, search, plan, guide, and saved places
- Local-first persistence for core content and saved state

### FastAPI Backend
- `GET /health`
- `POST /plan-itinerary`
- `POST /guide/message`
- OpenAI calls remain server-side
- Shared-secret auth and rate limiting live here

### Next.js Web Planning Layer
- Planning-focused homepage and `/plan` workflow
- Browser talks to local Next.js route handlers
- Route handlers proxy requests to the FastAPI backend
- No auth yet, no database yet

## Repository Structure

```text
CityScout/
├── CityScout/        # Native iOS app
├── backend/          # FastAPI + OpenAI backend
├── web/              # Next.js planning layer
├── docs/             # Product and architecture docs
├── CityScout.xcodeproj
├── CityScoutTests/
└── CityScoutUITests/
```

## Current Status

- iOS V1 flows are in place with destination-scoped navigation and local-first persistence
- itinerary generation, guide chat, map integration, and saved places are live in the app
- the backend includes validation, shared-secret auth, and tests
- the web app has a planning shell and a proxy layer for backend access
- browser requests do not call OpenAI directly

## Near-Term Roadmap

- finish wiring the web planning surface to the proxy-backed itinerary flow
- expand web itinerary review and sharing
- harden backend and web error handling and request tracing
- decide whether web auth should stay anonymous, use short-lived tokens, or move to accounts
- prepare for TestFlight and broader cross-surface QA

## How To Run The Backend

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
./.venv/bin/python -m pip install -r requirements.txt
./run_dev.sh
```

The API runs on `http://127.0.0.1:8000` by default. If that port is in use, `run_dev.sh` selects the next free port.

## How To Run The Web App

```bash
cd web
npm install
npm run dev
```

The web app runs at `http://localhost:3000`.

## Backend Config Notes

Backend environment variables:
- `APP_ENV`
- `OPENAI_API_KEY`
- `APP_SHARED_SECRET`
- `APP_ALLOWED_ORIGIN` or `APP_ALLOWED_ORIGINS`

The backend secret must stay server-side. The iOS app uses its own app configuration, and the web app uses Next.js route handlers to forward requests to the backend.

For local development:
- set backend env vars in `backend/.env`
- set web server-only env vars in `web/.env.local`
- point the web proxy at the backend host that your browser can reach

## Web Security Note

The browser must not call OpenAI directly.

The browser also should not receive the shared backend secret. Web requests should go through the Next.js route handlers, which keep backend secrets in server-only environment variables and proxy requests to FastAPI.

For public web deployment, prefer a backend-for-frontend proxy or a public-safe token/session model instead of exposing a static shared secret to browser JavaScript.

## Testing Readiness

- Simulator testing is stable for core iOS flows
- Real-device testing requires backend environment configuration and a reachable host
- The web app currently relies on manual verification
- TestFlight is a near-term target

## Local Verification

Use these commands before opening a PR:

### Backend

```bash
cd backend
python -m pip install -r requirements.txt
python -m pytest
bandit -r app -x tests
```

### Web

```bash
cd web
npm install
npm run lint
npm test
npm run build
```

### iOS

```bash
xcodebuild -project CityScout.xcodeproj -scheme CityScout -configuration Debug -sdk iphonesimulator -destination "generic/platform=iOS Simulator" clean build
```

## AI-assisted development

This repository uses Claude Code and similar tools for AI-assisted engineering. The following documents govern how AI tooling should interact with the codebase:

| Document | Purpose |
| --- | --- |
| [CLAUDE.md](./CLAUDE.md) | Repository-wide engineering instructions: rules, testing expectations, security constraints, definition of done |
| [AGENTS.md](./AGENTS.md) | Catalogue of current and planned AI agents/services, interaction principles, guardrails, and cost awareness |
| [.ai/skills/](./.ai/skills/) | Focused reusable skill documents for common tasks |

### Available skills

| Skill | When to use |
| --- | --- |
| [nextjs-api-routes.md](./.ai/skills/nextjs-api-routes.md) | Adding or modifying a web proxy route handler |
| [proxy-security.md](./.ai/skills/proxy-security.md) | Security review of the web-to-backend proxy layer |
| [testing-standards.md](./.ai/skills/testing-standards.md) | Writing or reviewing tests across all three surfaces |
| [ux-polish.md](./.ai/skills/ux-polish.md) | Building or refining web UI to the CityScout design standard |
| [deployment-checklist.md](./.ai/skills/deployment-checklist.md) | Pre-merge and pre-deploy verification |
| [fastapi-integration.md](./.ai/skills/fastapi-integration.md) | Adding routes, services, or schemas to the backend |

## License

CityScout is proprietary and not open source. See [LICENSE](./LICENSE) for the full restricted terms.

© 2026 Tim Finch. All rights reserved.
