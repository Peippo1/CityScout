# CityScout Web — Operations

Deployment, rollback, and incident response guide for the CityScout Next.js web layer.

---

## Environment variables

### Required (app will not function correctly without these)

| Variable | Where it goes | Purpose |
|---|---|---|
| `CITYSCOUT_API_BASE_URL` | Server-only | Base URL for the FastAPI backend |
| `CITYSCOUT_APP_SHARED_SECRET` | Server-only | Shared proxy secret injected into every backend request |
| `NEXT_PUBLIC_SUPABASE_URL` | Browser-safe | Supabase project URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Browser-safe | Supabase anon key (safe to expose — RLS enforces access) |

### Optional

| Variable | Where it goes | Purpose |
|---|---|---|
| `SUPABASE_SERVICE_ROLE_KEY` | Server-only | Required for `/internal/analytics`. Bypasses RLS — keep server-side. |
| `INTERNAL_ALLOWED_EMAILS` | Server-only | Comma-separated email allowlist for `/internal/analytics`. If unset, all authenticated users can access. |

### What happens when vars are missing

| Missing var | Symptom |
|---|---|
| `CITYSCOUT_API_BASE_URL` | `/api/plan-itinerary` returns `500 proxy_misconfigured` |
| `CITYSCOUT_APP_SHARED_SECRET` | `/api/plan-itinerary` returns `500 proxy_misconfigured` |
| `NEXT_PUBLIC_SUPABASE_URL` | Auth and saved itineraries silently fail |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Auth and saved itineraries silently fail |
| `SUPABASE_SERVICE_ROLE_KEY` | Analytics dashboard shows "unavailable" message |

---

## Health check

```
GET /api/health
```

Returns 200 when all required env vars are present. Returns 503 when any required var is missing. Reports variable presence/absence but never exposes values. Safe to use as a Vercel deployment health check or uptime monitor probe.

Example healthy response:
```json
{
  "status": "ok",
  "checks": {
    "env": {
      "status": "ok",
      "vars": {
        "CITYSCOUT_API_BASE_URL": "present",
        "CITYSCOUT_APP_SHARED_SECRET": "present",
        "NEXT_PUBLIC_SUPABASE_URL": "present",
        "NEXT_PUBLIC_SUPABASE_ANON_KEY": "present"
      }
    }
  }
}
```

Example degraded response (503):
```json
{
  "status": "degraded",
  "checks": {
    "env": {
      "status": "missing_vars",
      "vars": { "CITYSCOUT_API_BASE_URL": "missing", "..." : "present" },
      "missing": ["CITYSCOUT_API_BASE_URL"]
    }
  }
}
```

---

## Vercel deployment checklist

Before deploying a new release:

- [ ] All required env vars are set in Vercel project settings
- [ ] `npm test` passes locally on the branch
- [ ] `npm run build` passes locally on the branch
- [ ] Backend is deployed and healthy before deploying the web layer
- [ ] `CITYSCOUT_API_BASE_URL` points to the deployed backend URL (not localhost)
- [ ] `CITYSCOUT_APP_SHARED_SECRET` matches the backend's `CITYSCOUT_APP_SHARED_SECRET`

After deploying:

- [ ] Check `/api/health` — should return `200 ok`
- [ ] Load `/` — confirm homepage renders
- [ ] Load `/plan` — confirm itinerary form renders
- [ ] Generate a plan — confirm backend connectivity
- [ ] Check Vercel function logs for unexpected errors

---

## Supabase setup

1. Create a project at [supabase.com](https://supabase.com).
2. In **Authentication → URL Configuration**, add Redirect URLs:
   - Production: `https://your-app.vercel.app/auth/callback`
   - Local dev: `http://localhost:3000/auth/callback`
3. Run schema SQL in **SQL Editor → New query**:
   - `web/supabase/schema.sql` (saved itineraries + RLS)
   - `web/supabase/journal-schema.sql` (journal entries + RLS)
4. Both files are idempotent — safe to re-run.
5. Copy `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` from **Settings → API**.
6. Optional: copy `SUPABASE_SERVICE_ROLE_KEY` from the same page for the analytics dashboard.

### RLS enforcement

Row Level Security is active on both tables. All policies enforce `auth.uid() = user_id`. The service role key bypasses RLS — only use it in server-side code, never in the browser.

---

## Failure modes

### Backend unreachable

- **Symptom:** `/api/plan-itinerary` returns `502 proxy_error` or `504 upstream_timeout`
- **User sees:** "The itinerary service is temporarily unavailable."
- **Check:** Verify `CITYSCOUT_API_BASE_URL` is correct and the backend is running.
- **Rollback:** Revert the backend deployment; web layer will recover automatically.

### Supabase auth failure

- **Symptom:** Sign-in emails not arriving, auth callback returning errors
- **Check:** Verify Redirect URL is configured in Supabase Auth settings. Check Supabase logs.
- **Note:** Auth failures are logged as `auth_callback_failed` in structured logs.

### Rate limiting

- **Symptom:** Users receiving `429` responses
- **Check:** Vercel logs for `event:rate_limited` — includes `clientHash` for anomalous patterns.
- **Limits:** 10 req/10 min per IP for `/api/plan-itinerary`, 30 req/10 min for `/api/guide/message`.
- **Action:** Limits are in-memory per instance. A Vercel redeploy resets all counters.

### Proxy misconfigured

- **Symptom:** All itinerary generation returns `500` with `proxy_misconfigured`
- **Cause:** `CITYSCOUT_API_BASE_URL` or `CITYSCOUT_APP_SHARED_SECRET` env vars missing or empty
- **Fix:** Set the missing env var in Vercel and redeploy.

---

## Rollback steps

### Web layer rollback

1. Open the Vercel dashboard → Deployments
2. Find the last known-good deployment
3. Click **Promote to Production**
4. Verify `/api/health` returns 200 after promoting

### Backend rollback

The backend is deployed separately. Rollback via the backend's deployment platform (Render, Fly, etc.). The web layer will automatically recover once the backend is healthy.

---

## Smoke tests

After any deployment, run these manual checks:

1. `curl https://your-app.vercel.app/api/health` — expect `200 {"status":"ok"}`
2. Load `/plan` in a browser — confirm form renders
3. Submit a city name and generate an itinerary — confirm backend connectivity
4. Sign in with a magic link — confirm auth flow completes and redirects to `/`
5. Save an itinerary (if signed in) — confirm it appears on `/saved`

---

## Structured logs

The web layer emits structured JSON logs to stdout/stderr. See [docs/observability.md](./observability.md) for the full format, events table, and Vercel log search queries.

Key events to watch:
- `event:upstream_error` — backend is returning non-2xx
- `event:rate_limited` — unusual traffic volume from a client
- `event:auth_callback_failed` — auth flow is broken
- `event:save_failed` — Supabase write errors

---

## What is never logged

- Supabase service role key or anon key
- `CITYSCOUT_APP_SHARED_SECRET` or `CITYSCOUT_API_BASE_URL` values
- Raw IP addresses (only 16-char truncated SHA-256 hash)
- User itinerary text or journal entry content

See [docs/observability.md](./observability.md) for the complete list.
