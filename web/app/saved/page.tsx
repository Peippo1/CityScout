import { redirect } from "next/navigation";
import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { fetchSavedItineraries } from "@/lib/supabase/queries";
import { SiteShell } from "@/components/site-shell";
import { Surface } from "@/components/surface";
import { SavedItineraryList } from "./saved-itinerary-list";

export const metadata: Metadata = {
  title: "Saved itineraries — CityScout"
};

export default async function SavedPage() {
  const supabase = await createClient();
  const {
    data: { user }
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/auth/sign-in?next=/saved");
  }

  const items = await fetchSavedItineraries(supabase, user.id);

  return (
    <SiteShell compact>
      <section className="py-10 sm:py-12">
        <div className="max-w-2xl space-y-4">
          <p className="text-xs uppercase tracking-[0.28em] text-city-muted">Saved</p>
          <h1 className="font-editorial text-4xl leading-[0.98] text-city-ink sm:text-5xl">
            Your itineraries.
          </h1>
          <p className="max-w-xl text-base leading-7 text-city-muted">
            Itineraries you&apos;ve saved will appear here, private to your account.
          </p>
        </div>
      </section>

      <Surface
        title="Saved itineraries"
        description={
          items.length > 0
            ? `${items.length} saved ${items.length === 1 ? "itinerary" : "itineraries"}`
            : "Plans you have saved will appear here, ready to revisit."
        }
      >
        <SavedItineraryList initialItems={items} />
      </Surface>
    </SiteShell>
  );
}
