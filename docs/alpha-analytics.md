# CityScout — Alpha Analytics Dashboard

Lightweight internal analytics for the public alpha period. No external tracking, no third-party scripts.

---

## Access

Route: `/internal/analytics`

The page requires an authenticated session. Access is further restricted to emails in the `INTERNAL_ALLOWED_EMAILS` environment variable.

```bash
# .env.local (Vercel environment variable)
INTERNAL_ALLOWED_EMAILS=you@example.com,colleague@example.com
```

If `INTERNAL_ALLOWED_EMAILS` is empty or not set, **any authenticated user** can access the page. Set it in production.

---

## What it shows

| Metric | Source |
|---|---|
| Saved itineraries count | `saved_itineraries` table (total rows) |
| Journal entries count | `journal_entries` table (total rows) |
| Top destinations | `saved_itineraries.destination` — aggregated and sorted by frequency |
| Journal moods | `journal_entries.mood` — aggregated and sorted by frequency |
| Recent saves | Last 10 rows from `saved_itineraries` (all users) |

---

## Environment variables required

| Variable | Required | Notes |
|---|---|---|
| `SUPABASE_SERVICE_ROLE_KEY` | Yes | Server-side only. Never expose to the browser. Required for cross-user aggregate queries. |
| `INTERNAL_ALLOWED_EMAILS` | Recommended | Comma-separated list of emails allowed to access the dashboard. If unset, all authenticated users can access. |

`SUPABASE_SERVICE_ROLE_KEY` is available in your Supabase project under **Project Settings → API → service_role key**. Keep it server-side only — it bypasses Row Level Security.

---

## Implementation

| File | Role |
|---|---|
| `web/app/internal/analytics/page.tsx` | Server Component — auth check, allowlist, renders dashboard |
| `web/lib/supabase/admin.ts` | Creates a service-role Supabase client; returns null if key absent |
| `web/lib/supabase/analytics-queries.ts` | Aggregate queries; `aggregateCounts()` is exported and unit-tested |

The page degrades gracefully: if `SUPABASE_SERVICE_ROLE_KEY` is absent, it shows a message rather than crashing.

---

## What is not tracked

- Individual user identities are not displayed
- Raw itinerary content is not displayed
- No JavaScript tracking pixels or third-party scripts
- Rate-limit events are in structured logs (Vercel dashboard), not in this page

---

## Future additions

When usage grows:
- Add a time-range filter (last 7 days, 30 days, all time)
- Add a generations-per-day chart using Supabase's `created_at` timestamp
- Surface rate-limit events by reading Vercel log drain output
- Add a per-destination breakdown showing save rate vs generation count
