import type { Metadata } from "next";
import { SiteShell } from "@/components/site-shell";
import { PlanWorkspace } from "@/components/plan-workspace";
import { createClient } from "@/lib/supabase/server";
import { fetchSavedItinerary } from "@/lib/supabase/queries";
import type { PlanItineraryResponse } from "@/types/itinerary";

export const metadata: Metadata = {
  title: "Plan — CityScout"
};

type PlanPageProps = {
  searchParams: Promise<{ id?: string }>;
};

export default async function PlanPage({ searchParams }: PlanPageProps) {
  const { id } = await searchParams;

  const supabase = await createClient();
  const {
    data: { user }
  } = await supabase.auth.getUser();

  let initialItinerary: PlanItineraryResponse | null = null;
  let initialSavedId: string | null = null;

  if (id && user) {
    const saved = await fetchSavedItinerary(supabase, id, user.id);
    if (saved) {
      initialItinerary = saved.raw_response;
      initialSavedId = saved.id;
    }
  }

  return (
    <SiteShell compact>
      <section className="py-10 sm:py-12">
        <div className="max-w-2xl space-y-4">
          <p className="text-xs uppercase tracking-[0.28em] text-city-muted">Plan</p>
          <h1 className="font-editorial text-4xl leading-[0.98] text-city-ink sm:text-5xl">
            Shape a city day before you leave.
          </h1>
          <p className="max-w-xl text-base leading-7 text-city-muted">
            Build a day around pace, notes, and a travel style, then read the plan as a simple
            sequence of stops.
          </p>
        </div>
      </section>

      <PlanWorkspace
        userId={user?.id ?? null}
        initialItinerary={initialItinerary}
        initialSavedId={initialSavedId}
      />
    </SiteShell>
  );
}
