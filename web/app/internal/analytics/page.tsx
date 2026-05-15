import { redirect } from "next/navigation";
import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { fetchAnalyticsSummary } from "@/lib/supabase/analytics-queries";
import { SiteShell } from "@/components/site-shell";
import { Surface } from "@/components/surface";

export const metadata: Metadata = {
  title: "Analytics — CityScout Internal"
};

function getAllowedEmails(): Set<string> {
  const raw = process.env.INTERNAL_ALLOWED_EMAILS ?? "";
  return new Set(
    raw
      .split(",")
      .map((e) => e.trim().toLowerCase())
      .filter(Boolean)
  );
}

export default async function AnalyticsPage() {
  const supabase = await createClient();
  const {
    data: { user }
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/auth/sign-in?next=/internal/analytics");
  }

  const allowed = getAllowedEmails();
  if (allowed.size > 0 && !allowed.has((user.email ?? "").toLowerCase())) {
    redirect("/");
  }

  const adminClient = createAdminClient();
  const summary = adminClient ? await fetchAnalyticsSummary(adminClient) : null;

  const formattedDate = new Date().toLocaleDateString(undefined, { dateStyle: "medium" });

  return (
    <SiteShell compact>
      <section className="py-10 sm:py-12">
        <div className="max-w-2xl space-y-3">
          <p className="text-xs uppercase tracking-[0.28em] text-city-muted">Internal</p>
          <h1 className="font-editorial text-4xl leading-[0.98] text-city-ink sm:text-5xl">
            Alpha analytics.
          </h1>
          <p className="text-sm text-city-muted">{formattedDate} · {user.email}</p>
        </div>
      </section>

      {!summary ? (
        <Surface title="Unavailable" description="SUPABASE_SERVICE_ROLE_KEY is not configured.">
          <p className="text-sm text-city-muted">
            Add <code className="rounded bg-city-border/60 px-1.5 py-0.5 text-xs">SUPABASE_SERVICE_ROLE_KEY</code> to your environment variables to enable the analytics dashboard.
          </p>
        </Surface>
      ) : (
        <div className="space-y-8 pb-16">
          <div className="grid gap-4 sm:grid-cols-2">
            <StatCard label="Saved itineraries" value={summary.savedItinerariesCount} />
            <StatCard label="Journal entries" value={summary.journalEntriesCount} />
          </div>

          <Surface title="Top destinations" description={`${summary.topDestinations.length} destinations with saved itineraries`}>
            {summary.topDestinations.length === 0 ? (
              <p className="text-sm text-city-muted">No data yet.</p>
            ) : (
              <div className="space-y-0">
                {summary.topDestinations.map(({ label, count }, i) => (
                  <div
                    key={label}
                    className="flex items-center justify-between border-t border-city-border py-3 first:border-t-0 first:pt-0"
                  >
                    <div className="flex items-center gap-3">
                      <span className="w-5 text-xs text-city-muted">{i + 1}</span>
                      <span className="text-sm text-city-ink">{label}</span>
                    </div>
                    <span className="text-xs text-city-muted">{count}</span>
                  </div>
                ))}
              </div>
            )}
          </Surface>

          <Surface title="Journal moods" description="How travellers are describing their trips">
            {summary.topMoods.length === 0 ? (
              <p className="text-sm text-city-muted">No mood data yet.</p>
            ) : (
              <div className="flex flex-wrap gap-2">
                {summary.topMoods.map(({ label, count }) => (
                  <div
                    key={label}
                    className="flex items-center gap-1.5 rounded-full border border-city-border bg-white/60 px-3 py-1.5"
                  >
                    <span className="text-xs font-medium text-city-ink capitalize">{label}</span>
                    <span className="text-xs text-city-muted">{count}</span>
                  </div>
                ))}
              </div>
            )}
          </Surface>

          <Surface title="Recent saves" description="Last 10 itineraries saved across all users">
            {summary.recentSaves.length === 0 ? (
              <p className="text-sm text-city-muted">No saves yet.</p>
            ) : (
              <div className="space-y-0">
                {summary.recentSaves.map((item) => (
                  <div
                    key={`${item.destination}-${item.created_at}`}
                    className="flex items-center justify-between border-t border-city-border py-3 first:border-t-0 first:pt-0"
                  >
                    <div className="min-w-0">
                      <p className="text-xs uppercase tracking-[0.18em] text-city-muted">{item.destination}</p>
                      <p className="truncate text-sm text-city-ink">{item.title}</p>
                    </div>
                    <p className="ml-4 shrink-0 text-xs text-city-muted">
                      {formatDate(item.created_at)}
                    </p>
                  </div>
                ))}
              </div>
            )}
          </Surface>
        </div>
      )}
    </SiteShell>
  );
}

function StatCard({ label, value }: { label: string; value: number }) {
  return (
    <div className="rounded-2xl border border-city-border bg-white/55 p-5">
      <p className="text-xs uppercase tracking-[0.24em] text-city-muted">{label}</p>
      <p className="mt-2 font-editorial text-4xl text-city-ink">{value.toLocaleString()}</p>
    </div>
  );
}

function formatDate(value: string) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleDateString(undefined, { dateStyle: "medium" });
}
