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
    <section className={cn("glass-panel rounded-[28px] border border-white/10 shadow-glow", className)}>
      {(title || description) && (
        <div className="border-b border-white/10 px-6 pb-5 pt-6 sm:px-7">
          {title ? <h2 className="text-2xl font-semibold text-white">{title}</h2> : null}
          {description ? <p className="mt-2 text-sm leading-6 text-city-muted">{description}</p> : null}
        </div>
      )}
      <div className={cn("px-6 py-6 sm:px-7", !title && !description && "p-0")}>{children}</div>
    </section>
  );
}
