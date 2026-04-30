import Link from "next/link";
import type { ReactNode } from "react";
import { cn } from "@/lib/cn";

type SiteShellProps = {
  children: ReactNode;
  compact?: boolean;
};

export function SiteShell({ children, compact = false }: SiteShellProps) {
  return (
    <div className="min-h-screen text-city-ink">
      <header className="sticky top-0 z-30 border-b border-city-border bg-[rgba(248,246,241,0.86)] backdrop-blur-md">
        <div className={cn("mx-auto flex max-w-5xl items-center justify-between px-4 py-4 sm:px-6 lg:px-8", compact && "py-4")}>
          <Link href="/" className="flex items-center gap-3">
            <span className="grid h-10 w-10 place-items-center rounded-full border border-city-border bg-city-surface text-sm font-semibold shadow-soft">
              CS
            </span>
            <div>
              <p className="text-sm font-semibold tracking-wide text-city-ink">CityScout</p>
              <p className="text-xs uppercase tracking-[0.22em] text-city-muted">Planning surface</p>
            </div>
          </Link>

          <nav className="flex items-center gap-2 text-sm font-medium text-city-muted">
            <Link
              href="/"
              className="rounded-full border border-transparent px-4 py-2 transition duration-150 ease-out hover:border-city-border hover:bg-white/60 hover:text-city-ink focus-visible:border-city-ink focus-visible:bg-white focus-visible:text-city-ink focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-city-ink/15 focus-visible:ring-offset-2 focus-visible:ring-offset-city-background"
            >
              Home
            </Link>
            <Link
              href="/plan"
              className="rounded-full border border-city-border bg-city-ink px-4 py-2 text-white transition duration-150 ease-out hover:bg-white hover:text-city-ink focus-visible:border-city-ink focus-visible:bg-white focus-visible:text-city-ink focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-city-ink/15 focus-visible:ring-offset-2 focus-visible:ring-offset-city-background"
            >
              Plan
            </Link>
          </nav>
        </div>
      </header>

      <main className={cn("mx-auto max-w-5xl px-4 sm:px-6 lg:px-8", compact ? "pb-12" : "pb-16")}>{children}</main>
    </div>
  );
}
