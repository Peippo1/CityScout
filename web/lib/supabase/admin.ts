import { createClient } from "@supabase/supabase-js";

/**
 * Service-role Supabase client — bypasses RLS for admin/internal use.
 * Only call this from server-side code (Server Components, Route Handlers).
 * Never import this from client components or expose the result to the browser.
 *
 * Requires SUPABASE_SERVICE_ROLE_KEY env var. Returns null if absent so
 * callers can degrade gracefully (show "analytics unavailable").
 */
export function createAdminClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!url || !key) return null;

  return createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false }
  });
}
