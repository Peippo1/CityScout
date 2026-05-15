import { validateServerEnv, envStatusSummary } from "@/lib/env";

/**
 * GET /api/health
 *
 * Readiness endpoint. Returns 200 if all required environment variables are
 * present, 503 if any are missing. Does not expose secret values — only
 * reports whether each variable is "present" or "missing".
 *
 * Safe to expose publicly. No authentication required.
 */
export async function GET() {
  const { valid, missing } = validateServerEnv();
  const summary = envStatusSummary();

  const body = {
    status: valid ? "ok" : "degraded",
    checks: {
      env: {
        status: valid ? "ok" : "missing_vars",
        vars: summary,
        ...(missing.length > 0 ? { missing } : {})
      }
    }
  };

  return Response.json(body, {
    status: valid ? 200 : 503,
    headers: {
      "Cache-Control": "no-store, no-cache",
      "X-Content-Type-Options": "nosniff"
    }
  });
}
