/**
 * Server-side environment validation.
 * Only import this from server code (Route Handlers, Server Components).
 * Never import from client components — it reads process.env.
 */

export interface EnvVar {
  name: string;
  required: boolean;
  public: boolean;
}

const SERVER_ENV_VARS: EnvVar[] = [
  { name: "CITYSCOUT_API_BASE_URL", required: true, public: false },
  { name: "CITYSCOUT_APP_SHARED_SECRET", required: true, public: false },
  { name: "NEXT_PUBLIC_SUPABASE_URL", required: true, public: true },
  { name: "NEXT_PUBLIC_SUPABASE_ANON_KEY", required: true, public: true },
  { name: "SUPABASE_SERVICE_ROLE_KEY", required: false, public: false },
  { name: "INTERNAL_ALLOWED_EMAILS", required: false, public: false }
];

export interface EnvValidationResult {
  valid: boolean;
  missing: string[];
  present: string[];
}

export function validateServerEnv(): EnvValidationResult {
  const missing: string[] = [];
  const present: string[] = [];

  for (const entry of SERVER_ENV_VARS) {
    if (!entry.required) continue;
    const value = process.env[entry.name]?.trim();
    if (!value) {
      missing.push(entry.name);
    } else {
      present.push(entry.name);
    }
  }

  return {
    valid: missing.length === 0,
    missing,
    present
  };
}

export function getRequiredEnv(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

export function getOptionalEnv(name: string): string | undefined {
  return process.env[name]?.trim() || undefined;
}

/** Returns only the names (not values) of which required vars are present/absent. Safe to include in logs. */
export function envStatusSummary(): Record<string, "present" | "missing"> {
  const summary: Record<string, "present" | "missing"> = {};
  for (const entry of SERVER_ENV_VARS) {
    if (!entry.required) continue;
    const value = process.env[entry.name]?.trim();
    summary[entry.name] = value ? "present" : "missing";
  }
  return summary;
}
