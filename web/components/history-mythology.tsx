import { getHistoryMythology } from "@/lib/history-mythology";
import type { HistoryStory, RecommendedReading, StoryCategory } from "@/types/history-mythology";

type HistoryMythologyProps = {
  destination: string;
};

export function HistoryMythology({ destination }: HistoryMythologyProps) {
  const entry = getHistoryMythology(destination);

  if (!entry) return null;

  return (
    <div className="space-y-5 border-t border-city-border pt-5">
      <p className="text-xs uppercase tracking-[0.24em] text-city-muted">
        History &amp; mythology · {entry.place}
      </p>

      <div className="space-y-6">
        {entry.stories.map((story, i) => (
          <StoryCard key={i} story={story} />
        ))}
      </div>

      {entry.reading && entry.reading.length > 0 ? (
        <ReadingList items={entry.reading} />
      ) : null}
    </div>
  );
}

function StoryCard({ story }: { story: HistoryStory }) {
  return (
    <div className="space-y-2">
      <div className="flex flex-wrap items-center gap-2">
        <span className="rounded-full border border-city-border bg-white/60 px-3 py-1 text-xs font-medium text-city-muted">
          {categoryLabel(story.category)}
        </span>
        {story.landmark ? (
          <span className="text-xs uppercase tracking-[0.20em] text-city-muted/70">
            {story.landmark}
          </span>
        ) : null}
      </div>
      <h4 className="text-sm font-medium text-city-ink">{story.headline}</h4>
      <p className="max-w-3xl text-sm leading-6 text-city-muted">{story.body}</p>
    </div>
  );
}

function ReadingList({ items }: { items: RecommendedReading[] }) {
  return (
    <div className="rounded-2xl border border-city-border bg-white/55 p-4">
      <p className="text-xs uppercase tracking-[0.24em] text-city-muted">Recommended reading</p>
      <ul className="mt-3 space-y-3">
        {items.map((item, i) => (
          <li key={i} className="space-y-0.5">
            <p className="text-sm font-medium text-city-ink">
              {item.title}
              <span className="ml-2 font-normal text-city-muted">— {item.author}</span>
            </p>
            {item.note ? (
              <p className="text-xs leading-5 text-city-muted">{item.note}</p>
            ) : null}
          </li>
        ))}
      </ul>
    </div>
  );
}

function categoryLabel(category: StoryCategory): string {
  switch (category) {
    case "mythology": return "Mythology";
    case "history":   return "History";
    case "landmark":  return "This place";
    case "culture":   return "Culture";
  }
}
