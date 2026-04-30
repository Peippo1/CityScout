import { SiteShell } from "@/components/site-shell";
import { PlanWorkspace } from "@/components/plan-workspace";

export default function PlanPage() {
  return (
    <SiteShell compact>
      <div className="py-8 sm:py-10">
        <PlanWorkspace />
      </div>
    </SiteShell>
  );
}
