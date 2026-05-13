"use client";

import { useState } from "react";
import Link from "next/link";
import { saveItinerary } from "@/app/actions/itineraries";
import { Toast } from "@/components/toast";
import { useToast } from "@/hooks/use-toast";
import type { PlanItineraryResponse } from "@/types/itinerary";

type SaveState = "idle" | "saving" | "saved" | "error";

type SaveItineraryButtonProps = {
  itinerary: PlanItineraryResponse;
  userId: string | null;
  savedId: string | null;
  onSaved: (id: string) => void;
};

export function SaveItineraryButton({
  itinerary,
  userId,
  savedId,
  onSaved
}: SaveItineraryButtonProps) {
  const [saveState, setSaveState] = useState<SaveState>("idle");
  const { toast, showToast, dismiss } = useToast();

  // Already persisted (either from initial load or this session).
  if (savedId) {
    return (
      <Link
        href="/saved"
        className="rounded-full border border-city-border bg-white/60 px-3 py-1.5 text-xs font-medium text-city-muted transition duration-150 ease-out hover:border-city-ink/30 hover:text-city-ink focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-city-ink/15 focus-visible:ring-offset-2 focus-visible:ring-offset-city-background"
      >
        Saved ↗
      </Link>
    );
  }

  // Not signed in — prompt sign-in, return to /plan after.
  if (!userId) {
    return (
      <Link
        href="/auth/sign-in?next=/plan"
        className="rounded-full border border-city-border bg-white/60 px-3 py-1.5 text-xs font-medium text-city-muted transition duration-150 ease-out hover:border-city-ink/30 hover:text-city-ink focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-city-ink/15 focus-visible:ring-offset-2 focus-visible:ring-offset-city-background"
      >
        Sign in to save
      </Link>
    );
  }

  async function handleSave() {
    setSaveState("saving");
    try {
      const result = await saveItinerary(itinerary);
      setSaveState("saved");
      onSaved(result.id);
    } catch {
      setSaveState("error");
      showToast("Could not save itinerary. Please try again.", "error");
    }
  }

  const label =
    saveState === "saving" ? "Saving…" : saveState === "error" ? "Try again" : "Save itinerary";

  return (
    <>
      <button
        type="button"
        onClick={() => {
          void handleSave();
        }}
        disabled={saveState === "saving"}
        className="rounded-full border border-city-border bg-white/60 px-3 py-1.5 text-xs font-medium text-city-muted transition duration-150 ease-out hover:border-city-ink/30 hover:text-city-ink focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-city-ink/15 focus-visible:ring-offset-2 focus-visible:ring-offset-city-background disabled:cursor-not-allowed disabled:opacity-60"
      >
        {label}
      </button>
      {toast ? (
        <Toast
          message={toast.message}
          variant={toast.variant}
          toastKey={toast.key}
          onDismiss={dismiss}
        />
      ) : null}
    </>
  );
}
