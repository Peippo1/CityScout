/**
 * Lightweight structured logger for CityScout server-side code.
 *
 * Output is newline-delimited JSON to stdout/stderr. Vercel, Render, and
 * most cloud providers ingest this format and make it searchable by field.
 *
 * Rules:
 *   - Never log raw user text (itinerary body, journal entries, prompts).
 *   - Never log secrets, tokens, or env var values.
 *   - Never log raw IP addresses — always hash first with hashIp().
 *   - Keep log volume low: one entry per request on the happy path,
 *     plus one entry on error paths.
 */

export type LogLevel = "info" | "warn" | "error";

export interface LogFields {
  level: LogLevel;
  /** Route or action name, e.g. "/api/plan-itinerary", "saveItinerary" */
  route: string;
  /** Short event description, e.g. "request_complete", "rate_limited" */
  event: string;
  requestId?: string;
  /** Total handler duration in milliseconds */
  durationMs?: number;
  /** HTTP status code returned to the client */
  status?: number;
  /** Destination city — safe to log (user-provided, not sensitive) */
  destination?: string;
  /** Anonymised client identifier — use hashIp(), never a raw IP */
  clientHash?: string;
  /** Safe error description — no stack traces, no raw DB errors in prod */
  error?: string;
}

export function log(fields: LogFields): void {
  const entry = JSON.stringify({ ts: new Date().toISOString(), ...fields });

  if (fields.level === "error") {
    console.error(entry);
  } else if (fields.level === "warn") {
    console.warn(entry);
  } else {
    console.log(entry);
  }
}

/**
 * Returns a truncated SHA-256 hex digest of the IP address.
 * The result is 16 hex characters (64 bits of entropy) — enough to correlate
 * log lines without storing the raw IP. Not reversible in practice.
 *
 * For stronger anonymisation in production, replace with an HMAC-SHA-256
 * keyed by a rotating server-side secret.
 */
export async function hashIp(ip: string): Promise<string> {
  try {
    const data = new TextEncoder().encode(ip);
    const buffer = await crypto.subtle.digest("SHA-256", data);
    const hex = Array.from(new Uint8Array(buffer))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");
    return hex.slice(0, 16);
  } catch {
    return "unknown";
  }
}

/** Returns a monotonic timestamp for duration measurement. */
export function startTimer(): () => number {
  const start = Date.now();
  return () => Date.now() - start;
}
