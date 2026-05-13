"use client";

import { useState } from "react";
import { useSearchParams } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

export function SignInForm() {
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<"idle" | "loading" | "sent" | "error">("idle");
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const searchParams = useSearchParams();
  const next = searchParams.get("next") ?? "/";

  async function handleSubmit(event: React.FormEvent) {
    event.preventDefault();
    setStatus("loading");
    setErrorMessage(null);

    const supabase = createClient();
    const emailRedirectTo = `${window.location.origin}/auth/callback?next=${encodeURIComponent(next)}`;

    const { error } = await supabase.auth.signInWithOtp({
      email: email.trim(),
      options: { emailRedirectTo }
    });

    if (error) {
      console.error("[CityScout] Sign-in error:", error);
      setStatus("error");
      setErrorMessage("Could not send the sign-in link. Please try again.");
    } else {
      setStatus("sent");
    }
  }

  if (status === "sent") {
    return (
      <div className="rounded-3xl border border-city-border bg-white/55 p-8 text-center">
        <p className="text-sm font-medium text-city-ink">Check your email</p>
        <p className="mt-2 text-sm leading-6 text-city-muted">
          We sent a sign-in link to <span className="text-city-ink">{email}</span>. Click the link
          to continue.
        </p>
        <p className="mt-4 text-xs uppercase tracking-[0.22em] text-city-muted">
          You can close this tab.
        </p>
      </div>
    );
  }

  return (
    <form onSubmit={(e) => { void handleSubmit(e); }} className="space-y-5">
      {status === "error" && errorMessage ? (
        <div className="rounded-2xl border border-rose-300 bg-rose-50/80 px-4 py-3 text-sm text-rose-900/80">
          {errorMessage}
        </div>
      ) : null}

      <label className="block space-y-2">
        <span className="text-xs uppercase tracking-[0.24em] text-city-muted">Email address</span>
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="you@example.com"
          required
          autoComplete="email"
          className="w-full rounded-2xl border border-city-border bg-white/75 px-4 py-3 text-base text-city-ink outline-none transition duration-150 ease-out placeholder:text-city-muted focus:border-city-ink/30 focus:bg-white focus-visible:ring-2 focus-visible:ring-city-ink/15 focus-visible:ring-offset-2 focus-visible:ring-offset-city-background"
        />
      </label>

      <button
        type="submit"
        disabled={status === "loading"}
        className="inline-flex w-full items-center justify-center rounded-full border border-city-ink bg-city-ink px-5 py-3.5 text-sm font-medium text-white transition duration-150 ease-out hover:bg-white hover:text-city-ink focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-city-ink/15 focus-visible:ring-offset-2 focus-visible:ring-offset-city-background disabled:cursor-not-allowed disabled:opacity-60"
      >
        {status === "loading" ? "Sending…" : "Send sign-in link"}
      </button>

      <p className="text-center text-xs leading-6 text-city-muted">
        We&apos;ll email you a magic link. No password needed.
      </p>
    </form>
  );
}
