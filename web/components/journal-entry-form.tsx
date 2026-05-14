"use client";

import { useState } from "react";
import { cn } from "@/lib/cn";
import { createJournalEntry, updateJournalEntry } from "@/app/actions/journal";
import { JOURNAL_MOODS } from "@/types/journal";
import type { JournalEntry, JournalMood } from "@/types/journal";

const MOOD_LABELS: Record<JournalMood, string> = {
  reflective: "Reflective",
  adventurous: "Adventurous",
  relaxed: "Relaxed",
  energetic: "Energetic",
  romantic: "Romantic",
  overwhelmed: "Overwhelmed"
};

type JournalEntryFormProps = {
  itineraryId: string;
  destination: string;
  /** If provided, the form edits this existing entry. Otherwise it creates. */
  entry?: JournalEntry;
  onSuccess: () => void;
  onCancel: () => void;
};

export function JournalEntryForm({
  itineraryId,
  destination,
  entry,
  onSuccess,
  onCancel
}: JournalEntryFormProps) {
  const [title, setTitle] = useState(entry?.title ?? "");
  const [body, setBody] = useState(entry?.body ?? "");
  const [mood, setMood] = useState<JournalMood | null>(entry?.mood ?? null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const isEditing = Boolean(entry);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!body.trim()) {
      setError("Write something before saving.");
      return;
    }

    setSaving(true);
    setError(null);

    try {
      if (isEditing && entry) {
        await updateJournalEntry(entry.id, itineraryId, { title: title || null, body, mood });
      } else {
        await createJournalEntry({ itinerary_id: itineraryId, destination, title: title || null, body, mood });
      }
      onSuccess();
    } catch {
      setError(isEditing ? "Could not update entry. Please try again." : "Could not save entry. Please try again.");
      setSaving(false);
    }
  }

  return (
    <form
      onSubmit={(e) => { void handleSubmit(e); }}
      className="space-y-4 rounded-2xl border border-city-border bg-white/60 p-5"
    >
      {error ? (
        <p className="rounded-xl border border-rose-300 bg-rose-50/80 px-3 py-2 text-sm text-rose-900/80">
          {error}
        </p>
      ) : null}

      <label className="block space-y-1.5">
        <span className="text-xs uppercase tracking-[0.22em] text-city-muted">Title (optional)</span>
        <input
          type="text"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="A short title for this memory"
          maxLength={120}
          className="w-full rounded-xl border border-city-border bg-white/75 px-3 py-2.5 text-sm text-city-ink outline-none transition duration-150 placeholder:text-city-muted focus:border-city-ink/30 focus:bg-white focus-visible:ring-2 focus-visible:ring-city-ink/15 focus-visible:ring-offset-2 focus-visible:ring-offset-city-background"
        />
      </label>

      <label className="block space-y-1.5">
        <span className="text-xs uppercase tracking-[0.22em] text-city-muted">Memory</span>
        <textarea
          value={body}
          onChange={(e) => setBody(e.target.value)}
          placeholder="Write about this place, this day, how it felt…"
          rows={5}
          className="w-full resize-y rounded-xl border border-city-border bg-white/75 px-3 py-2.5 text-sm leading-6 text-city-ink outline-none transition duration-150 placeholder:text-city-muted focus:border-city-ink/30 focus:bg-white focus-visible:ring-2 focus-visible:ring-city-ink/15 focus-visible:ring-offset-2 focus-visible:ring-offset-city-background"
        />
      </label>

      <fieldset className="space-y-2">
        <legend className="text-xs uppercase tracking-[0.22em] text-city-muted">
          Mood (optional)
        </legend>
        <div className="flex flex-wrap gap-2">
          {JOURNAL_MOODS.map((m) => (
            <button
              key={m}
              type="button"
              onClick={() => setMood(mood === m ? null : m)}
              className={cn(
                "rounded-full border px-3 py-1.5 text-xs font-medium transition duration-150 ease-out focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-city-ink/15 focus-visible:ring-offset-2 focus-visible:ring-offset-city-background",
                mood === m
                  ? "border-city-ink bg-city-ink text-white"
                  : "border-city-border bg-white/60 text-city-muted hover:border-city-ink/30 hover:text-city-ink"
              )}
            >
              {MOOD_LABELS[m]}
            </button>
          ))}
        </div>
      </fieldset>

      <div className="flex items-center gap-2 pt-1">
        <button
          type="submit"
          disabled={saving}
          className="rounded-full border border-city-ink bg-city-ink px-4 py-2 text-xs font-medium text-white transition duration-150 ease-out hover:bg-white hover:text-city-ink focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-city-ink/15 focus-visible:ring-offset-2 focus-visible:ring-offset-city-background disabled:cursor-not-allowed disabled:opacity-60"
        >
          {saving ? "Saving…" : isEditing ? "Save changes" : "Save memory"}
        </button>
        <button
          type="button"
          onClick={onCancel}
          disabled={saving}
          className="rounded-full border border-city-border bg-white/60 px-4 py-2 text-xs font-medium text-city-muted transition duration-150 ease-out hover:border-city-ink/30 hover:text-city-ink focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-city-ink/15 focus-visible:ring-offset-2 focus-visible:ring-offset-city-background disabled:opacity-60"
        >
          Cancel
        </button>
      </div>
    </form>
  );
}
