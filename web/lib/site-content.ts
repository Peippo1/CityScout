export const explorationMoods = [
  {
    value: "mythic",
    label: "Mythic",
    description: "Ancient stories, sacred sites, and the layer of legend beneath the city."
  },
  {
    value: "quiet",
    label: "Quiet",
    description: "Fewer crowds, side streets, and the hours when a city breathes slowly."
  },
  {
    value: "romantic",
    label: "Romantic",
    description: "Beautiful light, unhurried meals, and places worth being slow in."
  },
  {
    value: "lively",
    label: "Lively",
    description: "Energy, movement, markets, and the parts of the city that hum."
  },
  {
    value: "slow-travel",
    label: "Slow travel",
    description: "One neighbourhood deeply rather than five lightly. Time to notice things."
  },
  {
    value: "food-focused",
    label: "Food focused",
    description: "Let the restaurants and cafes shape the route."
  },
  {
    value: "historical",
    label: "Historical",
    description: "The old city, its layers, and how it got here."
  },
  {
    value: "sea-view",
    label: "Sea view",
    description: "Coastal paths, harbours, and the feeling of a city that faces the sea."
  }
] as const;

export type ExplorationMoodValue = (typeof explorationMoods)[number]["value"];

export const travelStyles = [
  {
    value: "relaxed",
    label: "Relaxed",
    description: "Slow pace, coffee stops, and room to wander."
  },
  {
    value: "food-forward",
    label: "Food forward",
    description: "Plan around meals, cafes, and local specialties."
  },
  {
    value: "culture",
    label: "Culture",
    description: "Museums, landmarks, and city context."
  },
  {
    value: "neighborhoods",
    label: "Neighborhoods",
    description: "Walkable streets, local energy, and good views."
  },
  {
    value: "night-out",
    label: "Night out",
    description: "Evening energy, dinner, and a little momentum."
  }
] as const;
