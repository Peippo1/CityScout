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

Copy `.env.example` to `.env.local` and fill in your values. The app runs at `http://localhost:3000`.

## Vercel Deployment

Create a new Vercel project for this repository and use these project settings:

- Root Directory: `web`
- Install Command: `npm install`
- Build Command: `npm run build`

Add these environment variables in Vercel before deploying:

**Server-only (do not prefix with `NEXT_PUBLIC_`):**

- `CITYSCOUT_API_BASE_URL` — deployed CityScout backend URL (e.g. `https://your-backend.onrender.com`)
- `CITYSCOUT_APP_SHARED_SECRET` — shared proxy secret matching the backend

**Browser-safe (Supabase public values):**

- `NEXT_PUBLIC_SUPABASE_URL` — your Supabase project URL (Settings → API)
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` — your Supabase anon key (Settings → API)

The Supabase anon key is designed to be public — Row Level Security policies control data access, not the key itself. The backend secret and API base URL must remain server-side only.

Vercel Authentication can be disabled only after API rate limiting is active for `/api/plan-itinerary` and `/api/guide/message`.

## Supabase Setup

1. Create a project at [supabase.com](https://supabase.com).
2. In **Authentication → URL Configuration**, add your deployed Vercel URL as a Redirect URL: `https://your-app.vercel.app/auth/callback`.
3. For local development, also add `http://localhost:3000/auth/callback`.
4. Magic link (passwordless email) is enabled by default — no extra configuration needed.
5. Copy `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` from **Settings → API**.

## Database Setup

Run the schema SQL in the Supabase SQL Editor (**SQL Editor → New query**):

```text
web/supabase/schema.sql
```

The file is idempotent and safe to re-run. It creates or migrates the `saved_itineraries` table.

### Table: `saved_itineraries`

| Column | Type | Notes |
| --- | --- | --- |
| `id` | `uuid` | Primary key, auto-generated |
| `user_id` | `uuid` | FK → `auth.users`, cascades on delete |
| `destination` | `text` | City name, for list display |
| `title` | `text` | Short itinerary title |
| `summary` | `text?` | Optional one-line description |
| `raw_response` | `jsonb` | Full `PlanItineraryResponse` from the backend |
| `structured_itinerary_json` | `jsonb?` | Normalised display format (portable for iOS sync) |
| `created_at` | `timestamptz` | Set on insert |
| `updated_at` | `timestamptz` | Auto-updated by trigger on each `UPDATE` |

### RLS policies

| Policy | Operation | Rule |
| --- | --- | --- |
| `users_select_own` | SELECT | `auth.uid() = user_id` |
| `users_insert_own` | INSERT | `auth.uid() = user_id` (with check) |
| `users_delete_own` | DELETE | `auth.uid() = user_id` |

**RLS is required.** The web app uses the public anon key with authenticated sessions — without RLS, any signed-in user could read any row. Our Server Actions also filter by `user_id` as belt-and-suspenders.

### Migrating from v1 schema

If you ran the previous schema (which had a `payload` column instead of `raw_response`), re-running `schema.sql` will rename the column and add the missing fields automatically. No manual data migration is needed.

### Table: `journal_entries`

Also run `web/supabase/journal-schema.sql` (after `schema.sql`):

| Column | Type | Notes |
| --- | --- | --- |
| `id` | `uuid` | Primary key |
| `user_id` | `uuid` | FK → `auth.users`, cascades on delete |
| `itinerary_id` | `uuid` | FK → `saved_itineraries`, cascades on delete |
| `destination` | `text` | Denormalised city name |
| `title` | `text?` | Optional short title |
| `body` | `text` | Journal text (required) |
| `mood` | `text?` | One of: `reflective`, `adventurous`, `relaxed`, `energetic`, `romantic`, `overwhelmed` |
| `created_at` | `timestamptz` | Set on insert |
| `updated_at` | `timestamptz` | Auto-updated by trigger |

RLS policies: `journal_select_own`, `journal_insert_own`, `journal_update_own`, `journal_delete_own` — all enforce `auth.uid() = user_id`. Journal entries support UPDATE (for editing), unlike itineraries.

### Local development flow

1. Install [Supabase CLI](https://supabase.com/docs/guides/cli): `brew install supabase/tap/supabase`
2. `supabase login` and link to your project.
3. Or use the hosted Supabase SQL Editor for one-off runs of `schema.sql`.
4. Set `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` in `web/.env.local`.
5. Run `npm run dev` — auth and saved itineraries will work against your Supabase project.

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

## Contextual layers

### Local Intelligence

Destination-specific practical tips — cultural norms, transport, food notes, and local advice — rendered at the bottom of every generated itinerary.

- Seed data: `web/lib/local-intelligence/seed.ts` (10 cities)
- Matcher: `getIntelligence(destination)` — case-insensitive, alias-aware, returns `null` for unknown cities
- Component: `LocalIntelligence` — renders grouped tips; omits itself if no data

### History & Mythology

Curated narrative context — myths, historical events, landmark stories — with optional recommended reading. Designed to feel like a thoughtful travel companion, not an encyclopaedia.

- Seed data: `web/lib/history-mythology/seed.ts`
- Currently covers: Athens · Acropolis · Ancient Agora · Paros · Naxos · Marathon
- Matcher: `getHistoryMythology(place)` — matches cities and named landmarks; `getHistoryMythologyForPlaces(places[])` collects entries for an itinerary stop list
- Component: `HistoryMythology` — renders story cards by category (Mythology, History, This place, Culture) and a Recommended Reading panel; omits itself if no data

**Seed-data architecture:** Both layers use the same pattern — a typed seed array, a case-insensitive matcher, and a React component that renders `null` for unknown destinations. Adding a new city means adding one entry to the seed file. No build step or API call needed.

**Future AI-extension path:** Either matcher can be replaced with an async function that calls a CityScout backend endpoint. The component interface stays identical — swap `getHistoryMythology(destination)` for `await fetchHistoryMythology(destination)` and the rendering layer is untouched.

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

## Public alpha behaviour

CityScout is in public alpha. The `/plan` page displays a notice banner reminding users that itineraries are AI-assisted and should be checked before travel.

Additional alpha-mode behaviour:

- **Friendly errors** — rate limits, backend timeouts, and service unavailability all show calm, readable messages. Raw error codes are written to the browser console only.
- **Copy itinerary** — a "Copy itinerary" button appears after generation, writing a plain-text version of the plan to the clipboard.
- **Polished loading state** — while generating, the panel cycles through progress messages ("Building your city plan…", "Checking route flow…", "Adding practical travel notes…") with a simple step indicator.

No auth, no payment, and no new external services are required for any of these behaviours.

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
