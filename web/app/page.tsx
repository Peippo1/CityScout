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
    description: "The planner stays calm and readable so the plan feels like a curated note, not a settings panel."
  },
  {
    title: "Take it with you",
    description: "Plans travel well. The companion app keeps the day close once you're on the ground."
  }
];

export default function HomePage() {
  return (
    <SiteShell>
      <section className="grid gap-8 py-12 lg:grid-cols-[1.15fr_0.85fr] lg:items-end lg:py-16">
        <div className="space-y-8">
          <div className="space-y-5">
            <p className="text-xs uppercase tracking-[0.28em] text-city-muted">Before you arrive</p>
            <h1 className="max-w-3xl font-editorial text-5xl leading-[0.96] text-city-ink sm:text-6xl lg:text-7xl">
              Plan city days with the care of a good notebook.
            </h1>
            <p className="max-w-2xl text-lg leading-8 text-city-muted sm:text-xl">
              A calm, editorial surface built for pre-trip thinking — shaped around pace,
              neighbourhoods, and the details that make a day worth remembering.
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
              Plan before you go. Your phone takes over once you&apos;re there.
            </p>
          </div>
        </div>

        <Surface className="p-0">
          <div className="p-6 sm:p-7">
            <p className="text-xs uppercase tracking-[0.24em] text-city-muted">What it is</p>
            <h2 className="mt-3 max-w-md font-editorial text-3xl leading-tight text-city-ink sm:text-[2.2rem]">
              A quieter way to prepare.
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
            ["Share", "Keep the plan close. Move it to your phone when you're ready to leave."]
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
