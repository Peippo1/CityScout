import Link from "next/link";
import { SiteShell } from "@/components/site-shell";
import { Surface } from "@/components/surface";

const highlights = [
  {
    title: "Plan city days with intent",
    description: "Draft a day around pace, neighborhoods, food, and the kind of city experience you want."
  },
  {
    title: "Travel like a local",
    description: "CityScout keeps the focus on walkable plans, practical stops, and place-aware context."
  },
  {
    title: "Share a plan across surfaces",
    description: "The web app is the planning layer, while iOS stays the in-trip companion."
  }
];

export default function HomePage() {
  return (
    <SiteShell>
      <section className="grid gap-8 py-10 lg:grid-cols-[1.2fr_0.8fr] lg:items-end lg:py-14">
        <div className="space-y-8">
          <div className="space-y-5">
            <p className="text-sm uppercase tracking-[0.28em] text-city-muted">CityScout planning surface</p>
            <h1 className="max-w-3xl text-5xl font-semibold leading-none text-white sm:text-6xl lg:text-7xl">
              Plan city days with the same care you bring to the trip itself.
            </h1>
            <p className="max-w-2xl text-lg leading-8 text-city-muted sm:text-xl">
              CityScout helps users plan city days and travel like a local with a calm, destination-first
              planning surface built for desktop.
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-4">
            <Link
              href="/plan"
              className="inline-flex items-center rounded-full bg-white px-6 py-3 text-sm font-semibold text-city-ink transition hover:bg-city-accent hover:text-white"
            >
              Start planning
            </Link>
            <p className="text-sm text-city-muted">
              New web planning layer. No auth yet. No database yet.
            </p>
          </div>
        </div>

        <Surface className="p-6 sm:p-7">
          <div className="space-y-5">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-xs uppercase tracking-[0.25em] text-city-muted">What it is</p>
                <h2 className="mt-2 text-2xl font-semibold text-white">A planning layer, not a duplicate app.</h2>
              </div>
            </div>
            <div className="space-y-4">
              {highlights.map((item) => (
                <div key={item.title} className="rounded-2xl border border-white/10 bg-white/5 p-4">
                  <h3 className="text-base font-semibold text-white">{item.title}</h3>
                  <p className="mt-2 text-sm leading-6 text-city-muted">{item.description}</p>
                </div>
              ))}
            </div>
          </div>
        </Surface>
      </section>

      <section className="pb-14">
        <div className="grid gap-4 md:grid-cols-3">
          <Surface title="Plan" description="Draft the shape of the day before you travel.">
            <p className="text-sm leading-6 text-city-muted">
              Build a city day around pace, food, neighborhoods, and the kind of experience you want.
            </p>
          </Surface>
          <Surface title="Review" description="Keep the itinerary readable and easy to adjust.">
            <p className="text-sm leading-6 text-city-muted">
              Use the browser to scan a plan, check the sequence, and prepare what goes into the trip.
            </p>
          </Surface>
          <Surface title="Share" description="Send the plan to others without sharing the whole native app.">
            <p className="text-sm leading-6 text-city-muted">
              The web layer will support linkable, shareable planning while iOS remains the travel companion.
            </p>
          </Surface>
        </div>
      </section>
    </SiteShell>
  );
}
