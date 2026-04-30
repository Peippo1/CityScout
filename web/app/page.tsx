import Link from "next/link";
import { SiteShell } from "@/components/site-shell";
import { Surface } from "@/components/surface";

const highlights = [
  {
    title: "Plan the day, not just the stops",
    description: "CityScout helps shape the tempo, sequence, and tone of a city day before the trip begins."
  },
  {
    title: "Stay local in the details",
    description: "The web surface stays calm and readable so the plan feels like a curated note, not a dashboard."
  },
  {
    title: "Hand off to iOS when you travel",
    description: "Planning lives on the web; the native app remains the companion once the day starts."
  }
];

export default function HomePage() {
  return (
    <SiteShell>
      <section className="grid gap-8 py-12 lg:grid-cols-[1.15fr_0.85fr] lg:items-end lg:py-16">
        <div className="space-y-8">
          <div className="space-y-5">
            <p className="text-xs uppercase tracking-[0.28em] text-city-muted">CityScout planning surface</p>
            <h1 className="max-w-3xl font-editorial text-5xl leading-[0.96] text-city-ink sm:text-6xl lg:text-7xl">
              Plan city days with the care of a good notebook.
            </h1>
            <p className="max-w-2xl text-lg leading-8 text-city-muted sm:text-xl">
              CityScout helps travelers plan city days and travel like a local with a calm, editorial surface
              built for pre-trip thinking.
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <Link
              href="/plan"
              className="inline-flex items-center rounded-full border border-city-ink bg-city-ink px-5 py-2.5 text-sm font-medium text-white transition duration-150 ease-out hover:bg-white hover:text-city-ink"
            >
              Start planning
            </Link>
            <p className="max-w-md text-sm leading-6 text-city-muted">
              The web app is the planning layer. The iOS app remains the in-trip companion.
            </p>
          </div>
        </div>

        <Surface className="p-0">
          <div className="p-6 sm:p-7">
            <p className="text-xs uppercase tracking-[0.24em] text-city-muted">What it is</p>
            <h2 className="mt-3 max-w-md font-editorial text-3xl leading-tight text-city-ink sm:text-[2.2rem]">
              A planning layer, not a duplicate app.
            </h2>
          </div>
          <div className="divide-y divide-city-border border-y border-city-border">
            {highlights.map((item, index) => (
              <div key={item.title} className="grid gap-4 px-6 py-5 sm:grid-cols-[0.28fr_0.72fr] sm:px-7">
                <p className="text-xs uppercase tracking-[0.24em] text-city-muted">{String(index + 1).padStart(2, "0")}</p>
                <div>
                  <h3 className="text-base font-medium text-city-ink">{item.title}</h3>
                  <p className="mt-2 max-w-xl text-sm leading-6 text-city-muted">{item.description}</p>
                </div>
              </div>
            ))}
          </div>
        </Surface>
      </section>

      <section className="pb-14">
        <div className="grid gap-6 md:grid-cols-3">
          {[
            ["Plan", "Draft a city day around pace, neighborhoods, and the places that matter."],
            ["Review", "Read the route as a sequence of stops, not as a dense settings panel."],
            ["Share", "Move the plan between surfaces without exposing the whole native app."]
          ].map(([title, description]) => (
            <div key={title} className="border-t border-city-border pt-4">
              <p className="text-xs uppercase tracking-[0.24em] text-city-muted">{title}</p>
              <p className="mt-3 max-w-sm text-sm leading-6 text-city-muted">{description}</p>
            </div>
          ))}
        </div>
      </section>
    </SiteShell>
  );
}
