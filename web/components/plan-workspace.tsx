"use client";

import { useMemo, useState } from "react";
import { ApiError, planItinerary } from "@/lib/api";
import { cn } from "@/lib/cn";
import { travelStyles } from "@/lib/site-content";
import { Surface } from "@/components/surface";
import type { ItineraryBlock, ItineraryStop, PlanItineraryResponse } from "@/types/itinerary";

const initialDestination = "Paris";
const initialStyle = travelStyles[0]?.value ?? "relaxed";

type DisplayStop = {
  id: string;
  timeLabel: string;
  name: string;
  category: string;
  description: string;
  mapped: boolean;
};

export function PlanWorkspace() {
  const [destination, setDestination] = useState(initialDestination);
  const [style, setStyle] = useState(initialStyle);
  const [notes, setNotes] = useState("Coffee, art, and an easy walk with a few good food stops.");
  const [itinerary, setItinerary] = useState<PlanItineraryResponse | null>(null);
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [requestId, setRequestId] = useState<string | null>(null);

  const selectedStyle = useMemo(
    () => travelStyles.find((option) => option.value === style) ?? travelStyles[0],
    [style]
  );

  const displayStops = useMemo(() => buildDisplayStops(itinerary), [itinerary]);
  const mapStops = displayStops.slice(0, 6);
  const hasResults = Boolean(itinerary);

  async function handleGenerate() {
    const trimmedDestination = destination.trim();
    const trimmedNotes = notes.trim();

    if (!trimmedDestination) {
      setErrorMessage("Enter a destination before generating an itinerary.");
      setItinerary(null);
      setRequestId(null);
      return;
    }

    setLoading(true);
    setErrorMessage(null);

    try {
      const response = await planItinerary({
        destination: trimmedDestination,
        prompt:
          trimmedNotes ||
          `Plan a ${selectedStyle?.label.toLowerCase() ?? "relaxed"} day in ${trimmedDestination}.`,
        preferences: [selectedStyle?.label ?? "Relaxed"],
        saved_places: []
      });

      setItinerary(response);
      setRequestId(response.request_id ?? null);
    } catch (error) {
      setItinerary(null);

      if (error instanceof ApiError) {
        setRequestId(error.requestId ?? null);
        setErrorMessage(formatApiError(error));
      } else {
        setRequestId(null);
        setErrorMessage("The itinerary service is temporarily unavailable.");
      }
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="grid gap-6 xl:grid-cols-[0.9fr_1.1fr]">
      <Surface title="Plan a city day" description="Shape a day around destination, style, and a short planning note.">
        <div className="space-y-5">
          <label className="block space-y-2">
            <span className="text-sm font-medium text-white">Destination</span>
            <input
              value={destination}
              onChange={(event) => setDestination(event.target.value)}
              placeholder="Enter a city"
              className="w-full rounded-2xl border border-white/10 bg-black/20 px-4 py-3 text-base text-white outline-none transition placeholder:text-city-muted focus:border-city-accent focus:ring-2 focus:ring-city-accent/30"
            />
          </label>

          <fieldset className="space-y-3">
            <legend className="text-sm font-medium text-white">Travel style</legend>
            <div className="flex flex-wrap gap-2">
              {travelStyles.map((option) => {
                const active = option.value === style;
                return (
                  <button
                    key={option.value}
                    type="button"
                    onClick={() => setStyle(option.value)}
                    className={cn(
                      "rounded-full border px-4 py-2 text-sm font-medium transition",
                      active
                        ? "border-transparent bg-white text-city-ink"
                        : "border-white/10 bg-white/5 text-city-muted hover:border-white/20 hover:text-white"
                    )}
                  >
                    {option.label}
                  </button>
                );
              })}
            </div>
          </fieldset>

          <label className="block space-y-2">
            <span className="text-sm font-medium text-white">Notes</span>
            <textarea
              value={notes}
              onChange={(event) => setNotes(event.target.value)}
              rows={5}
              placeholder="What kind of day are you planning?"
              className="w-full resize-none rounded-2xl border border-white/10 bg-black/20 px-4 py-3 text-base text-white outline-none transition placeholder:text-city-muted focus:border-city-accent focus:ring-2 focus:ring-city-accent/30"
            />
          </label>

          <button
            type="button"
            onClick={() => {
              void handleGenerate();
            }}
            disabled={loading}
            className="inline-flex w-full items-center justify-center rounded-2xl bg-white px-5 py-3.5 text-sm font-semibold text-city-ink transition hover:bg-city-accent hover:text-white disabled:cursor-not-allowed disabled:opacity-70"
          >
            {loading ? "Generating draft..." : "Generate itinerary"}
          </button>
        </div>
      </Surface>

      <div className="grid gap-6">
        <Surface
          title={hasResults ? itinerary?.title ?? "Itinerary preview" : "Itinerary preview"}
          description={
            hasResults
              ? itinerary?.summary ?? "Generated itinerary"
              : "Generate a draft to see a city timeline, route summary, and map-ready placeholders."
          }
        >
          <div className="space-y-5">
            {loading ? <LoadingState /> : null}
            {!loading && errorMessage ? <ErrorState message={errorMessage} requestId={requestId} /> : null}
            {!loading && !errorMessage && !hasResults ? <EmptyState /> : null}
            {!loading && !errorMessage && hasResults ? (
              <GeneratedItinerary
                itinerary={itinerary}
                requestId={requestId}
                displayStops={displayStops}
              />
            ) : null}
          </div>
        </Surface>

        <Surface title="Map preview" description="A structured placeholder map panel ready for future markers.">
          <div className="relative overflow-hidden rounded-[24px] border border-white/10 bg-[radial-gradient(circle_at_20%_20%,rgba(136,214,255,0.18),transparent_16%),radial-gradient(circle_at_78%_30%,rgba(242,184,128,0.18),transparent_18%),linear-gradient(180deg,rgba(12,18,35,0.9),rgba(7,12,22,0.95))] p-5">
            <div className="absolute inset-0 opacity-70">
              <div className="absolute left-1/4 top-1/5 h-px w-3/4 bg-white/10" />
              <div className="absolute left-[16.6667%] top-1/2 h-px w-2/3 bg-white/10" />
              <div className="absolute left-1/4 top-3/4 h-px w-1/2 bg-white/10" />
              <div className="absolute left-[15%] top-0 h-full w-px bg-white/10" />
              <div className="absolute left-[48%] top-0 h-full w-px bg-white/10" />
              <div className="absolute left-[78%] top-0 h-full w-px bg-white/10" />
            </div>

            <div className="relative min-h-[280px] sm:min-h-[340px]">
              <div className="absolute left-10 top-10 rounded-full border border-city-accent/50 bg-city-accent/10 px-3 py-1 text-xs font-semibold text-city-accent">
                Planned route
              </div>
              <div className="absolute right-10 top-16 rounded-full border border-white/10 bg-white/5 px-3 py-1 text-xs font-semibold text-white">
                Saved places
              </div>
              <div className="absolute bottom-10 left-14 rounded-full border border-white/10 bg-white/5 px-3 py-1 text-xs font-semibold text-white">
                Marker rail
              </div>

              <div className="absolute inset-x-12 top-1/2 h-1 -translate-y-1/2 rounded-full bg-gradient-to-r from-city-accent via-white/40 to-city-warm/70" />
              {mapStops.map((stop, index) => (
                <div
                  key={stop.id}
                  className={cn("absolute flex items-center gap-2", mapMarkerPositionClass(index))}
                >
                  <div
                    className={cn(
                      "h-4 w-4 rounded-full border shadow-[0_0_0_6px_rgba(255,255,255,0.08)]",
                      stop.mapped
                        ? "border-city-accent bg-city-accent shadow-[0_0_0_8px_rgba(136,214,255,0.14)]"
                        : "border-white/70 bg-white"
                    )}
                  />
                  <div className="rounded-full border border-white/10 bg-black/50 px-3 py-1 text-[11px] font-medium text-white">
                    {stop.name}
                  </div>
                </div>
              ))}
            </div>
          </div>
          <p className="mt-4 text-sm leading-6 text-city-muted">
            This panel is a structured placeholder for future map markers and route overlays. It is intentionally
            data-shaped so the map SDK can slot in later without changing the page layout.
          </p>
        </Surface>
      </div>
    </div>
  );
}

function GeneratedItinerary({
  itinerary,
  requestId,
  displayStops
}: {
  itinerary: PlanItineraryResponse | null;
  requestId: string | null;
  displayStops: DisplayStop[];
}) {
  if (!itinerary) {
    return null;
  }

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-3 border-b border-white/10 pb-4">
        <div className="space-y-1">
          <p className="text-xs uppercase tracking-[0.24em] text-city-muted">Generated itinerary</p>
          <p className="text-sm text-city-muted">
            {itinerary.destination}
            {requestId ? <span className="ml-3 text-white/80">Request {requestId}</span> : null}
          </p>
        </div>
        <div className="text-right text-xs uppercase tracking-[0.22em] text-city-muted">
          {itinerary.generated_at ? <p>{formatGeneratedAt(itinerary.generated_at)}</p> : null}
          <p>{displayStops.length} stops</p>
        </div>
      </div>

      <div className="space-y-3">
        {displayStops.map((stop) => (
          <article key={stop.id} className="rounded-2xl border border-white/10 bg-white/5 p-4">
            <div className="flex flex-wrap items-start justify-between gap-3">
              <div className="space-y-1">
                <p className="text-xs uppercase tracking-[0.22em] text-city-muted">{stop.timeLabel}</p>
                <h3 className="text-lg font-semibold text-white">{stop.name}</h3>
              </div>
              <div className="flex items-center gap-2">
                <span className="rounded-full border border-white/10 px-3 py-1 text-xs font-medium text-city-muted">
                  {stop.category}
                </span>
                <span
                  className={cn(
                    "rounded-full px-3 py-1 text-xs font-medium",
                    stop.mapped
                      ? "border border-city-accent/40 bg-city-accent/10 text-city-accent"
                      : "border border-white/10 bg-white/5 text-city-muted"
                  )}
                >
                  {stop.mapped ? "Mapped" : "Unmatched"}
                </span>
              </div>
            </div>
            <p className="mt-3 text-sm leading-6 text-city-muted">{stop.description}</p>
          </article>
        ))}
      </div>

      <div className="grid gap-3 sm:grid-cols-3">
        <SummaryCard label="Morning" block={itinerary.morning} />
        <SummaryCard label="Afternoon" block={itinerary.afternoon} />
        <SummaryCard label="Evening" block={itinerary.evening} />
      </div>

      <div className="rounded-2xl border border-white/10 bg-black/20 p-4">
        <p className="text-xs uppercase tracking-[0.24em] text-city-muted">Notes</p>
        <div className="mt-3 space-y-2">
          {itinerary.notes.map((note) => (
            <p key={note} className="text-sm leading-6 text-city-muted">
              {note}
            </p>
          ))}
        </div>
      </div>
    </div>
  );
}

function SummaryCard({ label, block }: { label: string; block: ItineraryBlock }) {
  return (
    <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
      <p className="text-xs uppercase tracking-[0.24em] text-city-muted">{label}</p>
      <div className="mt-3 space-y-2">
        {block.activities.map((activity, index) => (
          <p key={`${label}-${index}`} className="text-sm leading-6 text-white/90">
            {activity}
          </p>
        ))}
      </div>
    </div>
  );
}

function LoadingState() {
  return (
    <div className="rounded-3xl border border-white/10 bg-white/5 p-6">
      <div className="flex items-center gap-3">
        <div className="h-3 w-3 animate-pulse rounded-full bg-city-accent" />
        <p className="text-sm font-medium text-white">Generating itinerary</p>
      </div>
      <p className="mt-2 text-sm leading-6 text-city-muted">
        CityScout is drafting a day plan and preparing the timeline.
      </p>
    </div>
  );
}

function ErrorState({ message, requestId }: { message: string; requestId: string | null }) {
  return (
    <div className="rounded-3xl border border-rose-500/30 bg-rose-500/10 p-6">
      <p className="text-sm font-medium text-rose-200">Could not generate itinerary</p>
      <p className="mt-2 text-sm leading-6 text-rose-100/80">{message}</p>
      {requestId ? <p className="mt-2 text-xs uppercase tracking-[0.22em] text-rose-100/60">Request {requestId}</p> : null}
    </div>
  );
}

function EmptyState() {
  return (
    <div className="grid gap-4">
      <div className="rounded-3xl border border-dashed border-white/10 bg-white/5 p-6">
        <p className="text-sm font-medium text-white">No itinerary generated yet</p>
        <p className="mt-2 text-sm leading-6 text-city-muted">
          Enter a city, choose a travel style, and generate a draft to see a timeline and route preview.
        </p>
      </div>
      <div className="grid gap-3">
        {["Morning", "Afternoon", "Evening"].map((slot) => (
          <div key={slot} className="rounded-2xl border border-white/10 bg-white/5 p-4">
            <p className="text-sm font-medium text-white">{slot}</p>
            <p className="mt-1 text-sm text-city-muted">Timeline cards will appear here once a plan is generated.</p>
          </div>
        ))}
      </div>
    </div>
  );
}

function buildDisplayStops(itinerary: PlanItineraryResponse | null): DisplayStop[] {
  if (!itinerary) {
    return [];
  }

  if (itinerary.stops && itinerary.stops.length > 0) {
    return itinerary.stops.map((stop) => toDisplayStop(stop));
  }

  return legacyBlocksToDisplayStops(itinerary);
}

function toDisplayStop(stop: ItineraryStop): DisplayStop {
  return {
    id: stop.id,
    timeLabel: stop.time_label,
    name: stop.name,
    category: stop.category,
    description: stop.description,
    mapped: Boolean(stop.latitude !== null && stop.longitude !== null)
  };
}

function legacyBlocksToDisplayStops(itinerary: PlanItineraryResponse): DisplayStop[] {
  const blocks: Array<[string, ItineraryBlock]> = [
    ["Morning", itinerary.morning],
    ["Afternoon", itinerary.afternoon],
    ["Evening", itinerary.evening]
  ];

  return blocks.flatMap(([timeLabel, block], blockIndex) =>
    block.activities.map((activity, activityIndex) => ({
      id: `${timeLabel.toLowerCase()}-${blockIndex}-${activityIndex}`,
      timeLabel,
      name: activity,
      category: "planned stop",
      description: activity,
      mapped: false
    }))
  );
}

function mapMarkerPositionClass(index: number) {
  const positions = [
    "left-10 top-28",
    "left-[36%] top-[38%]",
    "left-[60%] top-[30%]",
    "left-[72%] top-[64%]",
    "left-[20%] top-[70%]",
    "left-[44%] top-[58%]"
  ];

  return positions[index % positions.length];
}

function formatGeneratedAt(value: string) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return value;
  }

  return date.toLocaleString(undefined, {
    dateStyle: "medium",
    timeStyle: "short"
  });
}

function formatApiError(error: ApiError) {
  const parts = [error.message];
  if (error.code) {
    parts.push(`(${error.code})`);
  }
  return parts.join(" ");
}
