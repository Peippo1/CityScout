"use client";

import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

export function SignOutButton() {
  const router = useRouter();

  async function handleSignOut() {
    const supabase = createClient();
    await supabase.auth.signOut();
    router.refresh();
  }

  return (
    <button
      type="button"
      onClick={() => {
        void handleSignOut();
      }}
      className="rounded-full border border-city-border bg-white/60 px-4 py-2 text-sm font-medium text-city-muted transition duration-150 ease-out hover:border-city-ink/30 hover:text-city-ink focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-city-ink/15 focus-visible:ring-offset-2 focus-visible:ring-offset-city-background"
    >
      Sign out
    </button>
  );
}
