"use client";

import { Fragment, useEffect, useMemo, useState } from "react";
import { ApiError, planItinerary } from "@/lib/api";
import { cn } from "@/lib/cn";
import { travelStyles } from "@/lib/site-content";
import { Surface } from "@/components/surface";
import { SaveItineraryButton } from "@/components/save-itinerary-button";
import { LocalIntelligence } from "@/components/local-intelligence";
import type { ItineraryBlock, ItineraryStop, PlanItineraryResponse } from "@/types/itinerary";

const DEFAULT_DESTINATION = "Paris";
const DEFAULT_NOTES = "Coffee, art, and an easy walk with a few good food stops.";
const initialStyle = travelStyles[0]?.value ?? "relaxed";
type TravelStyleValue = (typeof travelStyles)[number]["value"];

const LOADING_STEPS = [
  "Building your city plan…",
  "Checking route flow…",
  "Adding practical travel notes…"
];

type DisplayStop = {
  id: string;
  timeLabel: string;
  name: string;
  category: string;
  description: string;
  mapped: boolean;
};

type PlanWorkspaceProps = {
  userId?: string | null;
  initialItinerary?: PlanItineraryResponse | null;
  initialSavedId?: string | null;
};

export function PlanWorkspace({
  userId = null,
  initialItinerary = null,
  initialSavedId = null
}: PlanWorkspaceProps) {
  const [destination, setDestination] = useState(
    initialItinerary?.destination ?? DEFAULT_DESTINATION
  );
  const [style, setStyle] = useState<TravelStyleValue>(initialStyle);
  const [notes, setNotes] = useState(DEFAULT_NOTES);
  const [itinerary, setItinerary] = useState<PlanItineraryResponse | null>(initialItinerary);
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [requestId, setRequestId] = useState<string | null>(
    initialItinerary?.request_id ?? null
  );
  // Track the saved-itinerary id so the save button can show the right state.
  const [savedId, setSavedId] = useState<string | null>(initialSavedId);

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
    setSavedId(null); // new generation — clear any saved state

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
      console.error("[CityScout] Itinerary generation failed:", error);

      if (error instanceof ApiError) {
        setRequestId(error.requestId ?? null);
        setErrorMessage(friendlyApiError(error));
      } else {
        setRequestId(null);
        setErrorMessage("The itinerary service is temporarily unavailable. Please try again.");
      }
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="space-y-8">
      <div className="rounded-2xl border border-amber-200/70 bg-amber-50/60 px-4 py-3 text-sm leading-6 text-amber-900/80">
        CityScout is in public alpha. Itineraries are AI-assisted and should be checked before
        travel.
      </div>

      <div className="grid gap-8 xl:grid-cols-[0.88fr_1.12fr]">
        <Surface
          title="Trip details"
          description="Destination, travel style, and the note that should shape the day."
        >
          <div className="space-y-5">
            <label className="block space-y-2">
              <span className="text-xs uppercase tracking-[0.24em] text-city-muted">
                Destination
              </span>
              <input
                value={destination}
                onChange={(event) => setDestination(event.target.value)}
                placeholder="Enter a city"
                className="w-full rounded-2xl border border-city-border bg-white/75 px-4 py-3 text-base text-city-ink outline-none transition duration-150 ease-out placeholder:text-city-muted focus:border-city-ink/30 focus:bg-white focus-visible:ring-2 focus-visible:ring-city-ink/15 focus-visible:ring-offset-2 focus-visible:ring-offset-city-background"
              />
            </label>

            <fieldset className="space-y-3">
              <legend className="text-xs uppercase tracking-[0.24em] text-city-muted">
                Travel style
              </legend>
              <div className="flex flex-wrap gap-2">
                {travelStyles.map((option) => {
                  const active = option.value === style;
                  return (
                    <button
                      key={option.value}
                      type="button"
                      onClick={() => setStyle(option.value)}
                      className={cn(
                        "rounded-full border px-4 py-2 text-sm font-medium transition duration-150 ease-out focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-city-ink/15 focus-visible:ring-offset-2 focus-visible:ring-offset-city-background",
                        active
                          ? "border-city-ink bg-city-ink text-white"
                          : "border-city-border bg-white/60 text-city-muted hover:border-city-ink/30 hover:text-city-ink"
                      )}
                    >
                      {option.label}
                    </button>
                  );
                })}
              </div>
            </fieldset>

            <label className="block space-y-2">
              <span className="text-xs uppercase tracking-[0.24em] text-city-muted">Notes</span>
              <textarea
                value={notes}
                onChange={(event) => setNotes(event.target.value)}
                rows={5}
                placeholder="What kind of day are you planning?"
                className="w-full resize-none rounded-2xl border border-city-border bg-white/75 px-4 py-3 text-base text-city-ink outline-none transition duration-150 ease-out placeholder:text-city-muted focus:border-city-ink/30 focus:bg-white focus-visible:ring-2 focus-visible:ring-city-ink/15 focus-visible:ring-offset-2 focus-visible:ring-offset-city-background"
              />
            </label>

            <button
              type="button"
              onClick={() => {
                void handleGenerate();
              }}
              disabled={loading}
              className="inline-flex w-full items-center justify-center rounded-full border border-city-ink bg-city-ink px-5 py-3.5 text-sm font-medium text-white transition duration-150 ease-out hover:bg-white hover:text-city-ink focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-city-ink/15 focus-visible:ring-offset-2 focus-visible:ring-offset-city-background disabled:cursor-not-allowed disabled:opacity-60"
            >
              {loading ? "Generating…" : "Generate itinerary"}
            </button>
          </div>
        </Surface>

        <div className="grid gap-8">
          <Surface
            title={hasResults ? itinerary?.title ?? "Itinerary preview" : "Itinerary preview"}
            description={
              hasResults
                ? itinerary?.summary ?? "Generated itinerary"
                : "Generate a draft to see a simple timeline, routing notes, and map-ready placeholders."
            }
          >
            <div className="space-y-5">
              {loading ? <LoadingState /> : null}
              {!loading && errorMessage ? (
                <ErrorState message={errorMessage} requestId={requestId} />
              ) : null}
              {!loading && !errorMessage && !hasResults ? <EmptyState /> : null}
              {!loading && !errorMessage && hasResults ? (
                <GeneratedItinerary
                  itinerary={itinerary}
                  requestId={requestId}
                  displayStops={displayStops}
                  userId={userId}
                  savedId={savedId}
                  onSaved={setSavedId}
                />
              ) : null}
            </div>
          </Surface>

          <Surface
            title="Map preview"
            description="A quiet placeholder for future markers and route overlays."
          >
            <div className="rounded-[24px] border border-city-border bg-white/55 p-5">
              <div className="grid min-h-[240px] gap-4 rounded-[20px] border border-dashed border-city-border bg-[linear-gradient(180deg,rgba(255,255,255,0.7),rgba(248,246,241,0.85))] p-4 sm:min-h-[300px]">
                <div className="flex flex-wrap items-center justify-between gap-3">
                  <div className="flex flex-wrap items-center gap-2">
                    <span className="rounded-full border border-city-border bg-white px-3 py-1 text-xs uppercase tracking-[0.22em] text-city-muted">
                      Planned route
                    </span>
                    <span className="rounded-full border border-city-border bg-white px-3 py-1 text-xs uppercase tracking-[0.22em] text-city-muted">
                      Saved places
                    </span>
                  </div>
                  <p className="text-xs uppercase tracking-[0.22em] text-city-muted">
                    Markers ready
                  </p>
                </div>

                <div className="relative flex-1">
                  <div className="absolute inset-x-4 top-1/2 h-px -translate-y-1/2 bg-city-border" />
                  <div className="absolute inset-y-5 left-1/4 w-px bg-city-border" />
                  <div className="absolute inset-y-5 left-1/2 w-px bg-city-border" />
                  <div className="absolute inset-y-5 left-3/4 w-px bg-city-border" />

                  {mapStops.map((stop, index) => (
                    <div
                      key={stop.id}
                      className={cn(
                        "absolute flex items-center gap-2",
                        mapMarkerPositionClass(index)
                      )}
                    >
                      <div
                        className={cn(
                          "h-3.5 w-3.5 rounded-full border bg-white shadow-[0_0_0_4px_rgba(17,17,17,0.05)]",
                          stop.mapped ? "border-city-ink" : "border-city-border"
                        )}
                      />
                      <div className="rounded-full border border-city-border bg-white/85 px-3 py-1 text-[11px] text-city-ink">
                        {stop.name}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
            <p className="mt-4 max-w-xl text-sm leading-6 text-city-muted">
              The layout is intentionally shaped for a future map SDK so markers can land without
              changing the page rhythm.
            </p>
          </Surface>
        </div>
      </div>
    </div>
  );
}

function GeneratedItinerary({
  itinerary,
  requestId,
  displayStops,
  userId,
  savedId,
  onSaved
}: {
  itinerary: PlanItineraryResponse | null;
  requestId: string | null;
  displayStops: DisplayStop[];
  userId: string | null;
  savedId: string | null;
  onSaved: (id: string) => void;
}) {
  const [copied, setCopied] = useState(false);

  if (!itinerary) {
    return null;
  }

  function handleCopy() {
    const text = buildItineraryText(itinerary!, displayStops);
    navigator.clipboard
      .writeText(text)
      .then(() => {
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
      })
      .catch(() => {
        // clipboard unavailable — silently skip
      });
  }

  const groups = groupStopsByPeriod(displayStops);

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-3 border-b border-city-border pb-4">
        <div className="space-y-1">
          <p className="text-xs uppercase tracking-[0.24em] text-city-muted">
            Generated itinerary
          </p>
          <p className="text-sm text-city-muted">
            {itinerary.destination}
            {requestId ? (
              <span className="ml-3 text-city-ink/70">Request {requestId}</span>
            ) : null}
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <div className="text-right text-xs uppercase tracking-[0.22em] text-city-muted">
            {itinerary.generated_at ? (
              <p>{formatGeneratedAt(itinerary.generated_at)}</p>
            ) : null}
            <p>{displayStops.length} stops</p>
          </div>
          <SaveItineraryButton
            itinerary={itinerary}
            userId={userId}
            savedId={savedId}
            onSaved={onSaved}
          />
          <button
            type="button"
            onClick={handleCopy}
            className="rounded-full border border-city-border bg-white/60 px-3 py-1.5 text-xs font-medium text-city-muted transition duration-150 ease-out hover:border-city-ink/30 hover:text-city-ink focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-city-ink/15 focus-visible:ring-offset-2 focus-visible:ring-offset-city-background"
          >
            {copied ? "Copied" : "Copy itinerary"}
          </button>
        </div>
      </div>

      <div className="space-y-0">
        {groups.map(({ period, stops: periodStops }, groupIndex) => (
          <Fragment key={period}>
            <div
              className={cn(
                "pb-1",
                groupIndex > 0 && "mt-1 border-t border-city-border pt-5"
              )}
            >
              <p className="text-xs uppercase tracking-[0.24em] text-city-muted">{period}</p>
            </div>
            {periodStops.map((stop) => (
              <article
                key={stop.id}
                className="border-t border-city-border py-4 first:border-t-0 first:pt-0"
              >
                <div className="grid gap-3 sm:grid-cols-[0.22fr_1fr] sm:gap-5">
                  <div className="space-y-1">
                    <p className="text-xs uppercase tracking-[0.22em] text-city-muted">
                      {stop.timeLabel}
                    </p>
                    <h3 className="text-lg font-medium text-city-ink">{stop.name}</h3>
                  </div>
                  <div className="space-y-3">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="rounded-full border border-city-border bg-white/60 px-3 py-1 text-xs font-medium text-city-muted">
                        {stop.category}
                      </span>
                      <span
                        className={cn(
                          "rounded-full px-3 py-1 text-xs font-medium",
                          stop.mapped
                            ? "border border-city-ink/20 bg-city-ink text-white"
                            : "border border-city-border bg-white/60 text-city-muted"
                        )}
                      >
                        {stop.mapped ? "Mapped" : "Unmatched"}
                      </span>
                    </div>
                    <p className="max-w-3xl text-sm leading-6 text-city-muted">
                      {stop.description}
                    </p>
                  </div>
                </div>
              </article>
            ))}
          </Fragment>
        ))}
      </div>

      <div className="grid gap-3 sm:grid-cols-3">
        <SummaryCard label="Morning" block={itinerary.morning} />
        <SummaryCard label="Afternoon" block={itinerary.afternoon} />
        <SummaryCard label="Evening" block={itinerary.evening} />
      </div>

      {itinerary.notes.length > 0 ? (
        <div className="rounded-2xl border border-city-border bg-white/55 p-4">
          <p className="text-xs uppercase tracking-[0.24em] text-city-muted">Practical notes</p>
          <div className="mt-3 space-y-2">
            {itinerary.notes.map((note) => (
              <p key={note} className="text-sm leading-6 text-city-muted">
                {note}
              </p>
            ))}
          </div>
        </div>
      ) : null}

      <LocalIntelligence destination={itinerary.destination} />
    </div>
  );
}

function SummaryCard({ label, block }: { label: string; block: ItineraryBlock }) {
  return (
    <div className="rounded-2xl border border-city-border bg-white/55 p-4">
      <p className="text-xs uppercase tracking-[0.24em] text-city-muted">{label}</p>
      <div className="mt-3 space-y-2">
        {block.activities.map((activity, index) => (
          <p key={`${label}-${index}`} className="text-sm leading-6 text-city-ink">
            {activity}
          </p>
        ))}
      </div>
    </div>
  );
}

function LoadingState() {
  const [step, setStep] = useState(0);

  useEffect(() => {
    const id = setInterval(() => {
      setStep((s) => (s + 1) % LOADING_STEPS.length);
    }, 1800);
    return () => clearInterval(id);
  }, []);

  return (
    <div className="rounded-3xl border border-city-border bg-white/55 p-6">
      <div className="flex items-center gap-3">
        <span className="h-2.5 w-2.5 animate-pulse rounded-full bg-city-ink" />
        <p className="text-sm font-medium text-city-ink" aria-live="polite">
          {LOADING_STEPS[step]}
        </p>
      </div>
      <div className="mt-4 flex gap-1.5">
        {LOADING_STEPS.map((_, i) => (
          <div
            key={i}
            className={cn(
              "h-0.5 flex-1 rounded-full transition-colors duration-700",
              i <= step ? "bg-city-ink" : "bg-city-border"
            )}
          />
        ))}
      </div>
    </div>
  );
}

function ErrorState({ message, requestId }: { message: string; requestId: string | null }) {
  return (
    <div className="rounded-3xl border border-rose-300 bg-rose-50/80 p-6">
      <p className="text-sm font-medium text-rose-950">Could not generate itinerary</p>
      <p className="mt-2 text-sm leading-6 text-rose-900/80">{message}</p>
      {requestId ? (
        <p className="mt-2 text-xs uppercase tracking-[0.22em] text-rose-900/60">
          Request {requestId}
        </p>
      ) : null}
    </div>
  );
}

function EmptyState() {
  return (
    <div className="grid gap-4">
      <div className="rounded-3xl border border-dashed border-city-border bg-white/55 p-6">
        <p className="text-sm font-medium text-city-ink">No itinerary generated yet</p>
        <p className="mt-2 text-sm leading-6 text-city-muted">
          Enter a city, choose a travel style, and generate a draft to see a timeline and route
          preview.
        </p>
      </div>
      <div className="grid gap-3">
        {["Morning", "Afternoon", "Evening"].map((slot) => (
          <div key={slot} className="rounded-2xl border border-city-border bg-white/55 p-4">
            <p className="text-sm font-medium text-city-ink">{slot}</p>
            <p className="mt-1 text-sm text-city-muted">
              Timeline cards will appear here once a plan is generated.
            </p>
          </div>
        ))}
      </div>
    </div>
  );
}

function groupStopsByPeriod(
  stops: DisplayStop[]
): Array<{ period: string; stops: DisplayStop[] }> {
  const groups: Array<{ period: string; stops: DisplayStop[] }> = [];
  for (const stop of stops) {
    const last = groups[groups.length - 1];
    if (last && last.period === stop.timeLabel) {
      last.stops.push(stop);
    } else {
      groups.push({ period: stop.timeLabel, stops: [stop] });
    }
  }
  return groups;
}

function buildDisplayStops(itinerary: PlanItineraryResponse | null): DisplayStop[] {
  if (!itinerary) return [];
  if (itinerary.stops && itinerary.stops.length > 0) {
    return itinerary.stops.map(toDisplayStop);
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
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleString(undefined, { dateStyle: "medium", timeStyle: "short" });
}

function friendlyApiError(error: ApiError): string {
  if (error.status === 429 || error.code === "rate_limited") {
    return "You've sent too many requests. Wait a few minutes and try again.";
  }
  if (error.code === "upstream_timeout" || error.code === "upstream_unavailable") {
    return "The itinerary service is temporarily unavailable. Please try again shortly.";
  }
  if (error.status === 500 || error.code === "proxy_misconfigured") {
    return "CityScout is temporarily unavailable. Please try again later.";
  }
  if (error.status === 422 || error.status === 400) {
    return error.message || "Please check your input and try again.";
  }
  return "Something went wrong generating your itinerary. Please try again.";
}

function buildItineraryText(
  itinerary: PlanItineraryResponse,
  stops: DisplayStop[]
): string {
  const lines: string[] = [];
  if (itinerary.title) lines.push(itinerary.title);
  if (itinerary.destination) lines.push(itinerary.destination);
  if (itinerary.summary) lines.push("", itinerary.summary);
  if (stops.length > 0) {
    lines.push("");
    for (const stop of stops) {
      lines.push(`${stop.timeLabel} — ${stop.name}`);
      if (stop.description && stop.description !== stop.name) lines.push(stop.description);
      lines.push("");
    }
  }
  if (itinerary.notes?.length > 0) {
    lines.push("Practical notes:");
    for (const note of itinerary.notes) lines.push(`• ${note}`);
  }
  return lines.join("\n").trim();
}
