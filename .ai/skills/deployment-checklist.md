# Skill: Deployment Checklist

## Purpose
Ensure the web app and backend are ready to deploy without regressions or exposed secrets. This checklist applies to any change that touches a deployed surface.

## When to use
- Before merging a PR that changes `web/` or `backend/`.
- Before a Vercel deployment or backend redeploy.
- After any change to environment variables, CORS config, or rate-limit settings.

---

## Web (Vercel / Next.js)

### Before merging
- [ ] `npm run lint` — no warnings or errors.
- [ ] `npm test` — all Vitest tests pass.
- [ ] `npm run build` — production build succeeds with no type errors.
- [ ] No `NEXT_PUBLIC_` prefix on secrets. `CITYSCOUT_APP_SHARED_SECRET` and `CITYSCOUT_API_BASE_URL` must be server-only.
- [ ] No new `console.log` calls that might leak request payloads or internal state in production.
- [ ] Error states show friendly messages, not raw API codes or stack traces.
- [ ] New route handlers follow the proxy security checklist in `.ai/skills/proxy-security.md`.

### Environment variables (Vercel)
Required:
- `CITYSCOUT_API_BASE_URL` — the backend URL reachable from Vercel's runtime (not localhost).
- `CITYSCOUT_APP_SHARED_SECRET` — must match `APP_SHARED_SECRET` in the backend deployment.

These must be set in the Vercel project settings under **Environment Variables**, not committed to the repository.

### Smoke test after deploy
1. Open the deployed `/plan` URL.
2. Submit a destination with the default style and notes.
3. Confirm the loading state appears.
4. Confirm a result renders with stops and the copy button.
5. Confirm that stopping the backend (or using a wrong secret) returns a friendly error, not a raw 401 or stack trace.
6. Check the browser DevTools network tab — confirm no secrets appear in request or response payloads.

---

## Backend (FastAPI)

### Before merging
- [ ] `python -m pytest` — all tests pass.
- [ ] `bandit -r app -x tests` — no high-severity findings.
- [ ] `APP_SHARED_SECRET` is set in the deployment environment, not hardcoded.
- [ ] `APP_ALLOWED_ORIGIN(S)` is tightly scoped to production domains — not `*`.
- [ ] Rate-limit settings have not been increased without review.
- [ ] New endpoints have tests covering auth, validation, and rate-limit paths.
- [ ] No OpenAI API key in any response body, log line, or error message.

### Environment variables (production backend)
Required:
- `APP_ENV` — `production`
- `OPENAI_API_KEY`
- `APP_SHARED_SECRET`
- `APP_ALLOWED_ORIGINS` — comma-separated list of allowed frontend origins

### Health check
```bash
curl https://<backend-host>/health
# Expected: {"status": "ok", "request_id": "..."}
```

---

## iOS (TestFlight / release)

- Do not touch iOS as part of web or backend deploys.
- iOS builds are gated by the separate `ios.yml` CI workflow.
- If you change the API contract, confirm that the iOS client is not broken before deploying the backend change.

---

## Cross-surface contract check

Before deploying a backend change that modifies response fields:
1. Confirm that legacy fields (`morning`, `afternoon`, `evening`, `notes`) are still present.
2. Confirm the iOS `PlanAPIService` still parses the response without errors.
3. Confirm the web `PlanItineraryResponse` type is still satisfied.
4. Update `docs/API_CONTRACT.md` if the contract changed.

---

## Rollback plan

**Web (Vercel):** Use the Vercel dashboard to re-deploy the previous successful deployment.  
**Backend:** Re-deploy the previous Docker image or git SHA. The backend is stateless (in-memory rate limiter resets on restart — expected).  
**iOS:** Rollback is a new TestFlight build; plan for this before removing legacy API fields.

---

## Definition of success
- All pre-merge checks pass.
- The smoke test passes against the deployed environment.
- No secrets in browser-accessible code or responses.
- The existing iOS client continues to work after a backend deploy.
