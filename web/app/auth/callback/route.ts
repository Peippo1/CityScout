import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import { NextResponse } from "next/server";
import { log } from "@/lib/logger";

export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get("code");
  const rawNext = searchParams.get("next") ?? "/";

  // Guard against open redirects — only allow relative paths on this origin.
  const next = rawNext.startsWith("/") ? rawNext : "/";

  if (code) {
    const cookieStore = await cookies();
    const supabase = createServerClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      {
        cookies: {
          getAll() {
            return cookieStore.getAll();
          },
          setAll(cookiesToSet) {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            );
          }
        }
      }
    );

    const { error } = await supabase.auth.exchangeCodeForSession(code);
    if (!error) {
      log({ level: "info", route: "/auth/callback", event: "auth_callback_success" });
      return NextResponse.redirect(`${origin}${next}`);
    }

    log({
      level: "error",
      route: "/auth/callback",
      event: "auth_callback_failed",
      error: error.message
    });
  }

  return NextResponse.redirect(`${origin}/auth/sign-in?error=callback_failed`);
}
