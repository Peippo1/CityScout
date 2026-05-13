import Link from "next/link";
import type { SavedItineraryRow } from "@/types/saved-itinerary";

type SavedItineraryCardProps = {
  item: SavedItineraryRow;
  onDelete: (id: string) => void;
  isDeleting?: boolean;
};

export function SavedItineraryCard({ item, onDelete, isDeleting = false }: SavedItineraryCardProps) {
  const formattedDate = formatDate(item.created_at);

  return (
    <article
      className="rounded-2xl border border-city-border bg-white/55 p-5 transition-opacity duration-200"
      style={{ opacity: isDeleting ? 0.4 : 1 }}
      aria-busy={isDeleting}
    >
      <div className="flex items-start justify-between gap-4">
        <div className="min-w-0 space-y-1">
          <p className="text-xs uppercase tracking-[0.22em] text-city-muted">{item.destination}</p>
          <h3 className="truncate text-base font-medium text-city-ink">{item.title}</h3>
          {item.summary ? (
            <p className="line-clamp-2 text-sm leading-6 text-city-muted">{item.summary}</p>
          ) : null}
        </div>

        <p className="shrink-0 text-xs uppercase tracking-[0.22em] text-city-muted">
          {formattedDate}
        </p>
      </div>

      <div className="mt-4 flex items-center gap-2">
        <Link
          href={`/plan?id=${item.id}`}
          className="rounded-full border border-city-ink bg-city-ink px-4 py-2 text-xs font-medium text-white transition duration-150 ease-out hover:bg-white hover:text-city-ink focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-city-ink/15 focus-visible:ring-offset-2 focus-visible:ring-offset-city-background"
        >
          Open
        </Link>
        <button
          type="button"
          onClick={() => onDelete(item.id)}
          disabled={isDeleting}
          className="rounded-full border border-city-border bg-white/60 px-4 py-2 text-xs font-medium text-city-muted transition duration-150 ease-out hover:border-rose-300 hover:bg-rose-50/60 hover:text-rose-900 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-city-ink/15 focus-visible:ring-offset-2 focus-visible:ring-offset-city-background disabled:cursor-not-allowed disabled:opacity-40"
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
