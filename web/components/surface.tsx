import type { ReactNode } from "react";
import { cn } from "@/lib/cn";

type SurfaceProps = {
  title?: string;
  description?: string;
  children: ReactNode;
  className?: string;
};

export function Surface({ title, description, children, className }: SurfaceProps) {
  return (
    <section className={cn("glass-panel rounded-[28px] border border-city-border shadow-soft", className)}>
      {(title || description) && (
        <div className="border-b border-city-border px-6 pb-5 pt-6 sm:px-7">
          {title ? <p className="text-xs uppercase tracking-[0.24em] text-city-muted">{title}</p> : null}
          {description ? <p className="mt-3 max-w-xl text-sm leading-6 text-city-muted">{description}</p> : null}
        </div>
      )}
      <div className={cn("px-6 py-6 sm:px-7", !title && !description && "p-0")}>{children}</div>
    </section>
  );
}
