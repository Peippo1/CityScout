import type { DraftItinerary, DraftItineraryStop, TravelStyleValue } from "@/types/itinerary";

function slugify(value: string) {
  return value
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

function buildStop(
  destination: string,
  style: TravelStyleValue,
  index: number,
  timeLabel: DraftItineraryStop["timeLabel"],
  name: string,
  category: DraftItineraryStop["category"],
  description: string
): DraftItineraryStop {
  const prefix = `${slugify(destination) || "city"}-${style}-${index + 1}`;

  return {
    id: `stop-${prefix}`,
    name,
    timeLabel,
    category,
    description,
    latitude: null,
    longitude: null,
    matchedPoiId: null,
    confidence: null
  };
}

export function buildMockItinerary(destination: string, style: TravelStyleValue, notes: string): DraftItinerary {
  const city = destination.trim() || "your city";
  const noteSnippet = notes.trim() || "a flexible city day";
  const title = `${city}: ${styleTitle(style)} day`;

  const stops = [
    buildStop(city, style, 0, "Morning", "Neighborhood coffee and breakfast", "food", `Ease into ${city} with a cafe stop and a calm start shaped by ${noteSnippet}.`),
    buildStop(city, style, 1, "Midday", "Primary sight or museum", "museum", `Anchor the middle of the day around a place that fits the tone of ${city}.`),
    buildStop(city, style, 2, "Afternoon", "Walkable district and local shop", "walk", `Use the afternoon for a slower walk through a district that feels local and easy to read.`),
    buildStop(city, style, 3, "Evening", "Dinner and a final view", "viewpoint", `Close the day with a dinner stop and a simple final scene before heading back.`)
  ];

  return {
    destination: city,
    title,
    summary: `A ${styleTitle(style).toLowerCase()} city day built around ${noteSnippet.toLowerCase()}.`,
    generatedAt: new Date().toISOString(),
    stops
  };
}

function styleTitle(style: TravelStyleValue) {
  switch (style) {
    case "food-forward":
      return "Food-forward";
    case "culture":
      return "Culture-led";
    case "neighborhoods":
      return "Neighborhood";
    case "night-out":
      return "Night-out";
    case "relaxed":
    default:
      return "Relaxed";
  }
}
