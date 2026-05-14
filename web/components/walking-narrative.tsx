import { getWalkingNarrative } from "@/lib/walking-narratives";
import type { NarrativeStop, NarrativeStopType } from "@/types/walking-narrative";

type WalkingNarrativeProps = {
  destination: string;
};

export function WalkingNarrative({ destination }: WalkingNarrativeProps) {
  const narrative = getWalkingNarrative(destination);

  if (!narrative) return null;

  return (
    <div className="space-y-5 border-t border-city-border pt-5">
      <div className="space-y-1">
        <p className="text-xs uppercase tracking-[0.24em] text-city-muted">
          Walking narrative · {narrative.durationMinutes} min
        </p>
        <p className="text-sm font-medium text-city-ink">{narrative.title}</p>
        <p className="text-sm leading-6 text-city-muted">{narrative.intro}</p>
      </div>

      <ol className="space-y-5">
        {narrative.stops.map((stop, index) => (
          <NarrativeStopCard key={stop.id} stop={stop} index={index + 1} />
        ))}
      </ol>
    </div>
  );
}

function NarrativeStopCard({
  stop,
  index
}: {
  stop: NarrativeStop;
  index: number;
}) {
  return (
    <li className="grid gap-3 sm:grid-cols-[1.5rem_1fr]">
      <span className="mt-0.5 hidden text-xs uppercase tracking-[0.20em] text-city-muted/60 sm:block">
        {String(index).padStart(2, "0")}
      </span>
      <div className="space-y-2">
        <div className="flex flex-wrap items-center gap-2">
          <h4 className="text-sm font-medium text-city-ink">{stop.name}</h4>
          <span className="rounded-full border border-city-border bg-white/60 px-2.5 py-0.5 text-xs font-medium text-city-muted">
            {stopTypeLabel(stop.type)}
          </span>
        </div>
        <p className="text-sm leading-6 text-city-muted">{stop.passage}</p>
        {stop.lookFor ? (
          <p className="text-xs leading-5 text-city-ink/60">
            <span className="font-medium">Look for:</span> {stop.lookFor}
          </p>
        ) : null}
      </div>
    </li>
  );
}

function stopTypeLabel(type: NarrativeStopType): string {
  switch (type) {
    case "approach":      return "Approach";
    case "landmark":      return "Landmark";
    case "viewpoint":     return "Viewpoint";
    case "history":       return "History";
    case "mythology":     return "Mythology";
    case "architecture":  return "Architecture";
    case "transition":    return "En route";
  }
}
