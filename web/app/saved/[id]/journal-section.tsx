"use client";

import { useOptimistic, useTransition, useState } from "react";
import { JournalEntryCard } from "@/components/journal-entry-card";
import { JournalEntryForm } from "@/components/journal-entry-form";
import { Toast } from "@/components/toast";
import { useToast } from "@/hooks/use-toast";
import { deleteJournalEntry } from "@/app/actions/journal";
import type { JournalEntry } from "@/types/journal";

type JournalSectionProps = {
  itineraryId: string;
  destination: string;
  initialEntries: JournalEntry[];
};

export function JournalSection({
  itineraryId,
  destination,
  initialEntries
}: JournalSectionProps) {
  const [, startTransition] = useTransition();
  const [isCreating, setIsCreating] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const { toast, showToast, dismiss } = useToast();

  const [optimisticEntries, removeOptimistic] = useOptimistic(
    initialEntries,
    (state: JournalEntry[], deletedId: string) =>
      state.filter((e) => e.id !== deletedId)
  );

  function handleDelete(id: string) {
    // Find the itinerary_id from the entry before removing it.
    startTransition(async () => {
      removeOptimistic(id);
      try {
        await deleteJournalEntry(id, itineraryId);
        showToast("Memory deleted.", "success");
      } catch {
        showToast("Could not delete this memory. Please try again.", "error");
      }
    });
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <p className="text-xs uppercase tracking-[0.24em] text-city-muted">
          {optimisticEntries.length > 0
            ? `${optimisticEntries.length} ${optimisticEntries.length === 1 ? "memory" : "memories"}`
            : "Journal"}
        </p>
        {!isCreating ? (
          <button
            type="button"
            onClick={() => {
              setEditingId(null);
              setIsCreating(true);
            }}
            className="rounded-full border border-city-ink bg-city-ink px-4 py-2 text-xs font-medium text-white transition duration-150 ease-out hover:bg-white hover:text-city-ink focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-city-ink/15 focus-visible:ring-offset-2 focus-visible:ring-offset-city-background"
          >
            Write a memory
          </button>
        ) : null}
      </div>

      {isCreating ? (
        <JournalEntryForm
          itineraryId={itineraryId}
          destination={destination}
          onSuccess={() => setIsCreating(false)}
          onCancel={() => setIsCreating(false)}
        />
      ) : null}

      {optimisticEntries.length === 0 && !isCreating ? (
        <div className="rounded-3xl border border-dashed border-city-border bg-white/55 p-6">
          <p className="text-sm font-medium text-city-ink">No memories yet</p>
          <p className="mt-2 text-sm leading-6 text-city-muted">
            Write something about this trip — a moment, a feeling, a detail worth keeping.
          </p>
        </div>
      ) : null}

      <div className="space-y-4">
        {optimisticEntries.map((entry) =>
          editingId === entry.id ? (
            <JournalEntryForm
              key={entry.id}
              itineraryId={itineraryId}
              destination={destination}
              entry={entry}
              onSuccess={() => setEditingId(null)}
              onCancel={() => setEditingId(null)}
            />
          ) : (
            <JournalEntryCard
              key={entry.id}
              entry={entry}
              onEdit={() => {
                setIsCreating(false);
                setEditingId(entry.id);
              }}
              onDelete={handleDelete}
            />
          )
        )}
      </div>

      {toast ? (
        <Toast
          message={toast.message}
          variant={toast.variant}
          toastKey={toast.key}
          onDismiss={dismiss}
        />
      ) : null}
    </div>
  );
}
