import { redirect } from "next/navigation";
import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { SiteShell } from "@/components/site-shell";
import { Surface } from "@/components/surface";

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

  return (
    <SiteShell compact>
      <section className="py-10 sm:py-12">
        <div className="max-w-2xl space-y-4">
          <p className="text-xs uppercase tracking-[0.28em] text-city-muted">Saved</p>
          <h1 className="font-editorial text-4xl leading-[0.98] text-city-ink sm:text-5xl">
            Your itineraries.
          </h1>
          <p className="max-w-xl text-base leading-7 text-city-muted">
            Itineraries you save from the planning surface will appear here, scoped to your
            account.
          </p>
        </div>
      </section>

      <Surface
        title="Saved itineraries"
        description="Plans you have saved will appear here, ready to revisit or share."
      >
        <div className="rounded-3xl border border-dashed border-city-border bg-white/55 p-6">
          <p className="text-sm font-medium text-city-ink">No saved itineraries yet</p>
          <p className="mt-2 text-sm leading-6 text-city-muted">
            Generate an itinerary on the{" "}
            <a
              href="/plan"
              className="text-city-ink underline underline-offset-2 transition hover:opacity-70"
            >
              plan page
            </a>{" "}
            and save it to keep it here.
          </p>
        </div>
      </Surface>
    </SiteShell>
  );
}
