import Link from "next/link";
import type { ReactNode } from "react";
import { cn } from "@/lib/cn";

type SiteShellProps = {
  children: ReactNode;
  compact?: boolean;
};

export function SiteShell({ children, compact = false }: SiteShellProps) {
  return (
    <div className="min-h-screen text-white">
      <header className="border-b border-white/10 bg-black/10 backdrop-blur-xl">
        <div className={cn("mx-auto flex max-w-7xl items-center justify-between px-4 py-4 sm:px-6 lg:px-8", compact && "py-4")}>
          <Link href="/" className="flex items-center gap-3">
            <span className="grid h-10 w-10 place-items-center rounded-2xl border border-white/10 bg-white/10 text-sm font-bold">
              CS
            </span>
            <div>
              <p className="text-sm font-semibold tracking-wide text-white">CityScout</p>
              <p className="text-xs text-city-muted">Planning surface</p>
            </div>
          </Link>

          <nav className="flex items-center gap-2 text-sm font-medium text-city-muted">
            <Link href="/" className="rounded-full px-4 py-2 transition hover:bg-white/10 hover:text-white">
              Home
            </Link>
            <Link href="/plan" className="rounded-full bg-white px-4 py-2 text-city-ink transition hover:bg-city-accent hover:text-white">
              Plan
            </Link>
          </nav>
        </div>
      </header>

      <main className={cn("mx-auto max-w-7xl px-4 sm:px-6 lg:px-8", compact ? "pb-12" : "pb-16")}>{children}</main>
    </div>
  );
}
