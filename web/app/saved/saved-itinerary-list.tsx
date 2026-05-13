"use client";

import { useOptimistic, useTransition, useState } from "react";
import Link from "next/link";
import { deleteItinerary } from "@/app/actions/itineraries";
import { SavedItineraryCard } from "@/components/saved-itinerary-card";
import type { SavedItineraryRow } from "@/types/saved-itinerary";

type Props = {
  initialItems: SavedItineraryRow[];
};

export function SavedItineraryList({ initialItems }: Props) {
  const [, startTransition] = useTransition();
  const [deleteError, setDeleteError] = useState<string | null>(null);

  const [optimisticItems, removeOptimistic] = useOptimistic(
    initialItems,
    (state: SavedItineraryRow[], deletedId: string) =>
      state.filter((item) => item.id !== deletedId)
  );

  function handleDelete(id: string) {
    setDeleteError(null);
    startTransition(async () => {
      removeOptimistic(id);
      try {
        await deleteItinerary(id);
      } catch {
        setDeleteError("Could not delete the itinerary. Please try again.");
      }
    });
  }

  if (optimisticItems.length === 0) {
    return <EmptyState />;
  }

  return (
    <div className="space-y-4">
      {deleteError ? (
        <div className="rounded-2xl border border-rose-300 bg-rose-50/80 px-4 py-3 text-sm text-rose-900/80">
          {deleteError}
        </div>
      ) : null}
      {optimisticItems.map((item) => (
        <SavedItineraryCard key={item.id} item={item} onDelete={handleDelete} />
      ))}
    </div>
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
