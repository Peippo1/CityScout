# Skill: Next.js API Route Handlers

## Purpose
Guide the correct pattern for writing and maintaining Next.js App Router route handlers in the CityScout web app. Every route handler in `web/app/api/` is a server-side proxy to the FastAPI backend.

## When to use
- Adding a new backend endpoint to the web surface.
- Modifying request validation, rate limiting, or error handling in an existing route.
- Debugging a proxy failure or unexpected response shape.

---

## Key rules

### Structure
- Route handlers live at `web/app/api/<path>/route.ts`.
- Export only the HTTP methods you support. Reject others with `405`.
- Use `NextRequest` from `next/server`, not the Web API `Request`.
- The shared proxy utility is `web/app/api/_lib/proxy.ts`. Use `proxyJsonToBackend()` and `enforceWebProxyRateLimit()` — do not re-implement them.

### Validation before forwarding
Always validate and sanitise before forwarding to the backend:
```typescript
// Trim strings, enforce length limits, filter arrays
const destination = rawDestination?.trim().slice(0, 80);
if (!destination) {
  return Response.json({ error: { code: "validation_error", message: "...", request_id } }, { status: 422 });
}
```

### Error responses
All errors must return structured JSON matching the established envelope:
```json
{ "error": { "code": "...", "message": "...", "request_id": "..." } }
```
Never let a raw backend error, stack trace, or unhandled exception reach the browser response.

### Request ID
Generate or propagate a `requestId` for every request:
```typescript
const requestId = request.headers.get("X-Request-Id") ?? crypto.randomUUID();
```
Pass it through to `proxyJsonToBackend` and include it in all error responses.

### Rate limiting
Call `enforceWebProxyRateLimit(request, requestId, "/path")` before forwarding. If it returns a Response, return that immediately.

### Method guard
```typescript
export async function GET() {
  return new Response(null, { status: 405, headers: { Allow: "POST" } });
}
```

---

## Anti-patterns

- **Calling FastAPI directly from `web/lib/api.ts`.** The browser-side client must only call local Next.js route handlers.
- **Returning raw backend error bodies.** Always normalise errors through the proxy error shape.
- **Skipping validation.** Even if the backend validates, the route handler is the first line of defence.
- **Reading env vars in components or client code.** `CITYSCOUT_API_BASE_URL` and `CITYSCOUT_APP_SHARED_SECRET` are server-only. Reading them outside a route handler or server component will expose them.
- **Forgetting the rate limiter.** Every proxied endpoint must call `enforceWebProxyRateLimit`.

---

## Example workflow: adding a new proxied endpoint

1. Create `web/app/api/<name>/route.ts`.
2. Export `GET()` returning 405 if the endpoint only accepts POST.
3. Parse and validate the request body; return 422 on failure.
4. Call `enforceWebProxyRateLimit` — return its response if non-null.
5. Call `proxyJsonToBackend` with the validated body.
6. Return the proxy result.
7. Write tests covering: 405 rejection, 422 validation, success, 429 rate limit, and 504 timeout.

---

## Definition of success
- Route returns 405 for unsupported methods.
- Route validates input and returns structured 422 on failure.
- Rate limiter is active.
- All error paths return the standard JSON error envelope.
- Tests pass for all covered paths.
- No secrets in response bodies or client-accessible code.
