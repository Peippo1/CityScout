# CityScout Web

This directory contains the Next.js planning surface for CityScout.

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
cp .env.example .env.local
npm run dev
```

Set `CITYSCOUT_API_BASE_URL` in `web/.env.local` to the CityScout backend URL. The app runs at `http://localhost:3000`.

## Vercel Deployment

Create a new Vercel project for this repository and use these project settings:

- Root Directory: `web`
- Install Command: `npm install`
- Build Command: `npm run build`

Add this environment variable in Vercel before deploying:

- `CITYSCOUT_API_BASE_URL`: your deployed CityScout backend URL, for example `https://your-render-backend-url.onrender.com` (server-only)
- `CITYSCOUT_APP_SHARED_SECRET`: shared proxy secret expected by the Render backend (server-only)

Do not expose these variables in browser JavaScript. Keep both as server-side Vercel environment variables only.
Vercel Authentication can be disabled only after API rate limiting is active for `/api/plan-itinerary` and `/api/guide/message`.

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
- The route handlers forward requests to the FastAPI backend using `CITYSCOUT_API_BASE_URL`.
- `CITYSCOUT_APP_SHARED_SECRET` must stay server-side.
- Do not expose the shared backend secret in browser JavaScript.
- For public web use, prefer a backend-for-frontend route handler or a public-safe token/session model instead of a static shared secret in the client.
- Proxy routes enforce per-IP rate limits, request-size caps, payload validation, and upstream timeouts, and always return concise JSON errors.
- Current per-IP limits (10-minute window): `/api/plan-itinerary` = 10 requests, `/api/guide/message` = 30 requests.

## Manual Verification

Use these steps when you want to verify the `/plan` flow in the browser:

1. Start the backend service and set `CITYSCOUT_API_BASE_URL` and, if required, `CITYSCOUT_APP_SHARED_SECRET` in `web/.env.local`.
2. Run `cd web && npm install && npm run dev`.
3. Open `http://localhost:3000/plan`.
4. Submit a destination, style, and notes.
5. Confirm the loading state appears first.
6. Confirm a generated itinerary renders with stop time, category, description, and mapped/unmatched badges.
7. Temporarily point the backend environment variable at an invalid backend or stop the backend to confirm the error state renders cleanly.
8. Refresh the page and confirm the empty state returns before a new submission.

## Manual Curl Checks

With `npm run dev` running in `web/`, run these checks:

1. Valid proxy request:
   `curl -i http://localhost:3000/api/plan-itinerary -H 'content-type: application/json' -d '{"destination":"Paris","prompt":"Plan a relaxed day","preferences":[],"saved_places":[]}'`
2. Rate limiting:
   repeat the same `/api/plan-itinerary` call more than 10 times within 10 minutes from the same IP and confirm `429` with JSON body and `Retry-After`.
3. Guide rate limiting:
   repeat `/api/guide/message` more than 30 times within 10 minutes from the same IP and confirm `429` with JSON body and `Retry-After`.
4. Oversized payload rejection:
   send a very large `prompt` and confirm `413` JSON.
5. Misconfigured env guard:
   unset `CITYSCOUT_API_BASE_URL` or `CITYSCOUT_APP_SHARED_SECRET` and confirm `500` JSON error from the proxy route.

## Testing

The web app now has a minimal test baseline:

- `npm test` runs Vitest once
- `npm run test:watch` runs Vitest in watch mode
- `npm run test:e2e` runs Playwright smoke tests
- `npm run lint` runs ESLint with the Next.js rules

The current baseline includes:

- one component test for the planning workspace shell
- one route-handler test for `/api/plan-itinerary`
- one Playwright smoke test for the homepage

Run the backend first when you want the e2e path to exercise the full stack.
