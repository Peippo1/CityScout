import type { JournalEntry, JournalMood } from "@/types/journal";

const MOOD_LABELS: Record<JournalMood, string> = {
  reflective: "Reflective",
  adventurous: "Adventurous",
  relaxed: "Relaxed",
  energetic: "Energetic",
  romantic: "Romantic",
  overwhelmed: "Overwhelmed"
};

type JournalEntryCardProps = {
  entry: JournalEntry;
  onEdit: () => void;
  onDelete: (id: string) => void;
  isDeleting?: boolean;
};

export function JournalEntryCard({
  entry,
  onEdit,
  onDelete,
  isDeleting = false
}: JournalEntryCardProps) {
  const formattedDate = formatDate(entry.created_at);
  const wasEdited = entry.updated_at !== entry.created_at;

  return (
    <article
      className="space-y-3 rounded-2xl border border-city-border bg-white/55 p-5 transition-opacity duration-200"
      style={{ opacity: isDeleting ? 0.4 : 1 }}
      aria-busy={isDeleting}
    >
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div className="space-y-0.5">
          {entry.title ? (
            <h3 className="text-sm font-medium text-city-ink">{entry.title}</h3>
          ) : null}
          <div className="flex flex-wrap items-center gap-2">
            <p className="text-xs uppercase tracking-[0.20em] text-city-muted">{formattedDate}</p>
            {wasEdited ? (
              <p className="text-xs uppercase tracking-[0.20em] text-city-muted/60">· edited</p>
            ) : null}
          </div>
        </div>
        {entry.mood ? (
          <span className="rounded-full border border-city-border bg-white/60 px-3 py-1 text-xs font-medium text-city-muted">
            {MOOD_LABELS[entry.mood]}
          </span>
        ) : null}
      </div>

      <p className="text-sm leading-6 text-city-ink/80 whitespace-pre-wrap">{entry.body}</p>

      <div className="flex items-center gap-2 pt-1">
        <button
          type="button"
          onClick={onEdit}
          disabled={isDeleting}
          className="rounded-full border border-city-border bg-white/60 px-3 py-1.5 text-xs font-medium text-city-muted transition duration-150 ease-out hover:border-city-ink/30 hover:text-city-ink focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-city-ink/15 focus-visible:ring-offset-2 focus-visible:ring-offset-city-background disabled:opacity-40"
        >
          Edit
        </button>
        <button
          type="button"
          onClick={() => onDelete(entry.id)}
          disabled={isDeleting}
          className="rounded-full border border-city-border bg-white/60 px-3 py-1.5 text-xs font-medium text-city-muted transition duration-150 ease-out hover:border-rose-300 hover:bg-rose-50/60 hover:text-rose-900 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-city-ink/15 focus-visible:ring-offset-2 focus-visible:ring-offset-city-background disabled:cursor-not-allowed disabled:opacity-40"
        >
          Delete
        </button>
      </div>
    </article>
  );
}

function formatDate(value: string) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleDateString(undefined, { dateStyle: "medium" });
}
