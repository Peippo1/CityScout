# Skill: Proxy Security

## Purpose
Enforce the security contract of the Next.js-to-FastAPI proxy layer. This layer is the trust boundary between the browser and the backend. Getting it wrong either exposes secrets or lets malformed requests reach OpenAI.

## When to use
- Reviewing or modifying `web/app/api/_lib/proxy.ts` or any file in `web/app/api/`.
- Adding a new proxied endpoint.
- Debugging a 401, 500, or unexpected backend error.
- Security review of the web layer.

---

## Key rules

### Secret handling
- `CITYSCOUT_APP_SHARED_SECRET` must **only** be read in `proxy.ts` server-side code.
- `CITYSCOUT_API_BASE_URL` must **only** be read in `proxy.ts` server-side code.
- Neither variable must appear in any file under `web/lib/`, `web/components/`, or `web/app/plan/`.
- If either variable is missing at runtime, the proxy must return `500` with code `proxy_misconfigured`. It must not silently pass an empty header to the backend.

### Rate limiting
- The web proxy maintains an in-memory `InMemoryRateLimiter`: 20 requests per 10 minutes per client IP per path.
- The rate limit key includes the backend path to prevent one endpoint from depleting another's budget.
- Call `enforceWebProxyRateLimit(request, requestId, backendPath)` before every backend forward.
- This does not replace backend rate limiting — both layers run.

### Request sanitisation
Before forwarding, the route handler must:
1. Trim all string inputs.
2. Enforce maximum lengths (destination: 80 chars, prompt: 1000 chars).
3. Filter and cap array inputs (preferences: max 10, saved_places: max 25).
4. Reject missing required fields with a 422 before the request reaches the proxy.

### Response hardening
- Never forward a raw backend response body without parsing and re-serialising through the expected shape.
- If the backend returns an unexpected content type, return a normalised error.
- Strip any internal backend headers before forwarding to the browser.
- Return `504` with `upstream_timeout` on timeout; return `503` with `upstream_unavailable` on connection failure.

### Error envelope
Every non-2xx response from the proxy must match:
```json
{
  "error": {
    "code": "<snake_case_code>",
    "message": "<human-readable message>",
    "request_id": "<uuid>"
  }
}
```
This shape is what `web/lib/api.ts` parses into `ApiError`. Breaking this shape breaks all client-side error handling.

### Request tracing
- Every request must carry a `requestId` (generated or propagated from `X-Request-Id`).
- The `requestId` must appear in the response JSON `error.request_id` and in the `X-Request-Id` response header.
- Log failures at `console.error` with the `requestId` so Vercel logs are searchable.

---

## Anti-patterns

- **Forwarding env vars to the client.** The `NEXT_PUBLIC_` prefix would publish them. Never add it to these variables.
- **Silent misconfiguration.** If `CITYSCOUT_APP_SHARED_SECRET` is `undefined`, do not send an empty header — return 500 immediately.
- **Swallowing rate-limit responses.** `enforceWebProxyRateLimit` returns a `Response | null`. If non-null, return it immediately without forwarding.
- **Trusting the backend error shape blindly.** The backend may return HTML on a cold-start failure. The proxy must handle non-JSON responses gracefully.
- **Re-implementing the rate limiter per route.** Use the shared `enforceWebProxyRateLimit` in `_lib/proxy.ts`.

---

## Security checklist for a new route

- [ ] Reads no env vars directly — delegates to `proxyJsonToBackend`.
- [ ] Validates and trims all inputs before forwarding.
- [ ] Calls `enforceWebProxyRateLimit` before forwarding.
- [ ] Returns 405 for unsupported methods.
- [ ] Returns 422 (not 400) for validation failures with a structured body.
- [ ] Returns structured JSON errors on all non-2xx paths.
- [ ] Does not log request payloads that may contain PII.
- [ ] Test covers the `proxy_misconfigured` path (missing env vars).

---

## Definition of success
- No secret leaves the server-side runtime.
- All error responses use the standard JSON envelope.
- Rate limiter fires correctly in tests.
- `bandit -r app -x tests` reports no high-severity findings on backend code.
- `npm test` passes including the route test suite.
