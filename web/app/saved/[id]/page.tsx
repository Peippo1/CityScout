import { notFound, redirect } from "next/navigation";
import Link from "next/link";
import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { fetchSavedItinerary } from "@/lib/supabase/queries";
import { fetchJournalEntries } from "@/lib/supabase/journal-queries";
import { SiteShell } from "@/components/site-shell";
import { Surface } from "@/components/surface";
import { JournalSection } from "./journal-section";

type PageProps = {
  params: Promise<{ id: string }>;
};

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { id } = await params;
  const supabase = await createClient();
  const {
    data: { user }
  } = await supabase.auth.getUser();

  if (!user) return { title: "Itinerary — CityScout" };

  const itinerary = await fetchSavedItinerary(supabase, id, user.id);
  return {
    title: itinerary
      ? `${itinerary.title} — CityScout`
      : "Itinerary — CityScout"
  };
}

export default async function SavedItineraryPage({ params }: PageProps) {
  const { id } = await params;

  const supabase = await createClient();
  const {
    data: { user }
  } = await supabase.auth.getUser();

  if (!user) {
    redirect(`/auth/sign-in?next=/saved/${id}`);
  }

  const [itinerary, journalEntries] = await Promise.all([
    fetchSavedItinerary(supabase, id, user.id),
    fetchJournalEntries(supabase, id, user.id)
  ]);

  if (!itinerary) notFound();

  const stops = itinerary.structured_itinerary_json?.stops ?? [];
  const formattedDate = new Date(itinerary.created_at).toLocaleDateString(undefined, {
    dateStyle: "medium"
  });

  return (
    <SiteShell compact>
      <section className="py-10 sm:py-12">
        <div className="space-y-2">
          <Link
            href="/saved"
            className="inline-flex items-center gap-1.5 text-xs uppercase tracking-[0.22em] text-city-muted transition hover:text-city-ink"
          >
            ← Saved
          </Link>
          <p className="text-xs uppercase tracking-[0.28em] text-city-muted">
            {itinerary.destination}
          </p>
          <h1 className="font-editorial text-4xl leading-[0.98] text-city-ink sm:text-5xl">
            {itinerary.title}
          </h1>
          {itinerary.summary ? (
            <p className="max-w-xl text-base leading-7 text-city-muted">{itinerary.summary}</p>
          ) : null}
          <p className="text-xs uppercase tracking-[0.22em] text-city-muted">
            {formattedDate} · {stops.length} {stops.length === 1 ? "stop" : "stops"}
          </p>
        </div>
      </section>

      <div className="space-y-8 pb-16">
        {stops.length > 0 ? (
          <Surface title="Itinerary" description="Your plan, stop by stop.">
            <div className="space-y-0">
              {stops.map((stop) => (
                <div
                  key={stop.id}
                  className="flex gap-4 border-t border-city-border py-3 first:border-t-0 first:pt-0"
                >
                  <p className="w-24 shrink-0 text-xs uppercase tracking-[0.18em] text-city-muted pt-0.5">
                    {stop.timeLabel}
                  </p>
                  <div className="min-w-0 space-y-0.5">
                    <p className="text-sm font-medium text-city-ink">{stop.name}</p>
                    <p className="text-sm leading-5 text-city-muted line-clamp-2">
                      {stop.description}
                    </p>
                  </div>
                </div>
              ))}
            </div>
            <div className="mt-4 border-t border-city-border pt-4">
              <Link
                href={`/plan?id=${id}`}
                className="text-xs uppercase tracking-[0.22em] text-city-muted transition hover:text-city-ink"
              >
                Reopen in planner →
              </Link>
            </div>
          </Surface>
        ) : (
          <div className="text-sm text-city-muted">
            <Link
              href={`/plan?id=${id}`}
              className="text-xs uppercase tracking-[0.22em] text-city-muted transition hover:text-city-ink"
            >
              Reopen in planner →
            </Link>
          </div>
        )}

        <Surface
          title="Journal"
          description="Notes, reflections, and memories attached to this itinerary."
        >
          <JournalSection
            itineraryId={id}
            destination={itinerary.destination}
            initialEntries={journalEntries}
          />
        </Surface>
      </div>
    </SiteShell>
  );
}
