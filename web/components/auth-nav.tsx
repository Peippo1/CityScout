import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { SignOutButton } from "@/components/sign-out-button";

export async function AuthNav() {
  const supabase = await createClient();
  const {
    data: { user }
  } = await supabase.auth.getUser();

  if (user) {
    return (
      <div className="flex items-center gap-2">
        <span className="hidden max-w-[160px] truncate text-xs text-city-muted sm:block">
          {user.email}
        </span>
        <Link
          href="/saved"
          className="rounded-full border border-city-border bg-white/60 px-4 py-2 text-sm font-medium text-city-muted transition duration-150 ease-out hover:border-city-ink/30 hover:text-city-ink focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-city-ink/15 focus-visible:ring-offset-2 focus-visible:ring-offset-city-background"
        >
          Saved
        </Link>
        <SignOutButton />
      </div>
    );
  }

  return (
    <Link
      href="/auth/sign-in"
      className="rounded-full border border-city-border bg-white/60 px-4 py-2 text-sm font-medium text-city-muted transition duration-150 ease-out hover:border-city-ink/30 hover:text-city-ink focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-city-ink/15 focus-visible:ring-offset-2 focus-visible:ring-offset-city-background"
    >
      Sign in
    </Link>
  );
}
