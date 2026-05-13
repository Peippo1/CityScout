"use client";

import { useOptimistic, useTransition, useState } from "react";
import Link from "next/link";
import { deleteItinerary } from "@/app/actions/itineraries";
import { SavedItineraryCard } from "@/components/saved-itinerary-card";
import { Toast } from "@/components/toast";
import { useToast } from "@/hooks/use-toast";
import type { SavedItineraryRow } from "@/types/saved-itinerary";

type Props = {
  initialItems: SavedItineraryRow[];
};

export function SavedItineraryList({ initialItems }: Props) {
  const [, startTransition] = useTransition();
  const { toast, showToast, dismiss } = useToast();

  const [optimisticItems, removeOptimistic] = useOptimistic(
    initialItems,
    (state: SavedItineraryRow[], deletedId: string) =>
      state.filter((item) => item.id !== deletedId)
  );

  function handleDelete(id: string) {
    startTransition(async () => {
      removeOptimistic(id);
      try {
        await deleteItinerary(id);
        showToast("Itinerary deleted.", "success");
      } catch {
        showToast("Could not delete the itinerary. Please try again.", "error");
      }
    });
  }

  if (optimisticItems.length === 0) {
    return <EmptyState />;
  }

  return (
    <>
      <div className="space-y-4">
        {optimisticItems.map((item) => (
          <SavedItineraryCard key={item.id} item={item} onDelete={handleDelete} />
        ))}
      </div>
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

function EmptyState() {
  return (
    <div className="rounded-3xl border border-dashed border-city-border bg-white/55 p-6">
      <p className="text-sm font-medium text-city-ink">No saved itineraries yet</p>
      <p className="mt-2 text-sm leading-6 text-city-muted">
        Generate an itinerary on the{" "}
        <Link
          href="/plan"
          className="text-city-ink underline underline-offset-2 transition hover:opacity-70"
        >
          plan page
        </Link>{" "}
        and save it to keep it here.
      </p>
    </div>
  );
}
