# CityScout Web

This directory contains the new Next.js planning surface for CityScout.

## Scope

- Next.js App Router
- TypeScript
- TailwindCSS
- no auth yet
- no database yet
- browser calls local Next.js route handlers
- typed API client forwards through the local proxy layer

## Purpose

The web app is the planning and sharing layer for CityScout. The native iOS app remains the primary in-trip travel companion.

No license is granted by this repository. See the root [LICENSE](../LICENSE) file for the full restricted terms.

## Run Locally

```bash
cd web
npm install
npm run dev
```

The app runs at `http://localhost:3000`.

## Structure

```text
web/
├── app/
├── components/
├── lib/
├── types/
├── public/
├── next.config.mjs
├── tailwind.config.mjs
├── postcss.config.mjs
└── tsconfig.json
```

## Notes

- The homepage introduces CityScout as a planning surface.
- `/plan` is a local UI shell with placeholder itinerary and map panels.
- The browser calls `web/lib/api.ts`, which targets local Next.js route handlers under `/api/...`.
- The route handlers forward requests to the FastAPI backend with server-only env vars.
- `CITYSCOUT_API_BASE_URL` and `CITYSCOUT_APP_SHARED_SECRET` must stay server-side.
- Do not expose the shared backend secret in browser JavaScript.
- For public web use, prefer a backend-for-frontend route handler or a public-safe token/session model instead of a static shared secret in the client.

## Manual Verification

Use these steps when you want to verify the `/plan` flow in the browser:

1. Start the backend service and set `CITYSCOUT_API_BASE_URL` and `CITYSCOUT_APP_SHARED_SECRET` in `web/.env.local`.
2. Run `cd web && npm install && npm run dev`.
3. Open `http://localhost:3000/plan`.
4. Submit a destination, style, and notes.
5. Confirm the loading state appears first.
6. Confirm a generated itinerary renders with stop time, category, description, and mapped/unmatched badges.
7. Temporarily point the proxy env vars at an invalid backend or stop the backend to confirm the error state renders cleanly.
8. Refresh the page and confirm the empty state returns before a new submission.

## Testing

The web app now has a minimal test baseline:

- `npm test` runs Vitest once
- `npm run test:watch` runs Vitest in watch mode
- `npm run test:e2e` runs Playwright smoke tests
- `npm run lint` runs the Next.js ESLint rules

The current baseline includes:

- one component test for the planning workspace shell
- one route-handler test for `/api/plan-itinerary`
- one Playwright smoke test for the homepage

Run the backend first when you want the e2e path to exercise the full stack.
