import { getIntelligence } from "@/lib/local-intelligence";
import type { IntelligenceCategory, IntelligenceTip } from "@/types/local-intelligence";

type LocalIntelligenceProps = {
  destination: string;
};

export function LocalIntelligence({ destination }: LocalIntelligenceProps) {
  const intelligence = getIntelligence(destination);

  if (!intelligence) return null;

  const grouped = groupByCategory(intelligence.tips);
  const order: IntelligenceCategory[] = ["cultural", "transport", "practical", "food"];
  const presentCategories = order.filter((c) => grouped[c]?.length);

  return (
    <div className="rounded-2xl border border-city-border bg-white/55 p-5">
      <p className="text-xs uppercase tracking-[0.24em] text-city-muted">
        Local intelligence · {destination}
      </p>
      <div className="mt-4 grid gap-4 sm:grid-cols-2">
        {presentCategories.map((category) => (
          <CategoryGroup
            key={category}
            category={category}
            tips={grouped[category] ?? []}
          />
        ))}
      </div>
    </div>
  );
}

function CategoryGroup({
  category,
  tips
}: {
  category: IntelligenceCategory;
  tips: IntelligenceTip[];
}) {
  return (
    <div className="space-y-2">
      <p className="text-xs uppercase tracking-[0.20em] text-city-muted/70">
        {categoryLabel(category)}
      </p>
      <ul className="space-y-2">
        {tips.map((tip, i) => (
          <li key={i} className="text-sm leading-6 text-city-muted">
            {tip.tip}
          </li>
        ))}
      </ul>
    </div>
  );
}

function groupByCategory(
  tips: IntelligenceTip[]
): Partial<Record<IntelligenceCategory, IntelligenceTip[]>> {
  const result: Partial<Record<IntelligenceCategory, IntelligenceTip[]>> = {};
  for (const tip of tips) {
    if (!result[tip.category]) result[tip.category] = [];
    result[tip.category]!.push(tip);
  }
  return result;
}

function categoryLabel(category: IntelligenceCategory): string {
  switch (category) {
    case "cultural":
      return "Culture";
    case "transport":
      return "Getting around";
    case "practical":
      return "Practical";
    case "food":
      return "Food & drink";
  }
}
