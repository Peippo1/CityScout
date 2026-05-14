import type { DestinationIntelligence } from "@/types/local-intelligence";

/** Bump when any entry is added, removed, or substantively changed. */
export const LOCAL_INTELLIGENCE_SEED_VERSION = "1.0.0";

export const intelligenceSeed: DestinationIntelligence[] = [
  {
    destination: "Paris",
    aliases: ["paris, france"],
    tips: [
      { category: "cultural", tip: "Greet shop owners with \"Bonjour\" before asking for anything — it makes a noticeable difference." },
      { category: "cultural", tip: "Tipping is appreciated but not obligatory. Rounding up or leaving a euro or two is the norm." },
      { category: "transport", tip: "A carnet (10-trip metro book) is cheaper than single tickets for a day of exploration." },
      { category: "transport", tip: "Vélib' bikes are easy to rent from any station. Good for short hops between arrondissements." },
      { category: "practical", tip: "Most museums are free the first Sunday of each month — arrive early." },
      { category: "food", tip: "Lunch menus (formule) at sit-down restaurants usually offer three courses for significantly less than dinner." }
    ]
  },
  {
    destination: "Tokyo",
    aliases: ["tokyo, japan"],
    tips: [
      { category: "cultural", tip: "Talking on the phone while on public transport is considered impolite. Calls are kept for designated areas." },
      { category: "cultural", tip: "Walking and eating at the same time is generally frowned upon outside of street-food zones." },
      { category: "transport", tip: "The IC card (Suica or Pasmo) works on almost every train, subway, and bus in the city." },
      { category: "transport", tip: "Last trains end around midnight. Know your station's final departure time before a late night." },
      { category: "practical", tip: "7-Eleven, FamilyMart, and Lawson ATMs reliably accept foreign cards — bank ATMs often do not." },
      { category: "food", tip: "Lining up outside a ramen or sushi shop is a good signal — the queue usually moves quickly." }
    ]
  },
  {
    destination: "New York",
    aliases: ["new york city", "nyc", "new york, usa"],
    tips: [
      { category: "transport", tip: "The subway runs 24 hours but gets slower late at night. Check service alerts before heading out." },
      { category: "transport", tip: "A 7-day unlimited MetroCard is worthwhile if you're making more than four trips a day." },
      { category: "cultural", tip: "Tipping 18–20% is the standard expectation at restaurants, bars, and taxis." },
      { category: "practical", tip: "Tap water is excellent here — carry a reusable bottle and refill freely." },
      { category: "food", tip: "Brunch lines on weekends can be long. Walk-ins at dinner on weekdays are often much easier." }
    ]
  },
  {
    destination: "London",
    aliases: ["london, uk", "london, england"],
    tips: [
      { category: "transport", tip: "Tap your contactless card or phone directly on Tube readers — no Oyster card needed." },
      { category: "transport", tip: "Buses are often faster than the Tube for short east-west journeys in central London." },
      { category: "cultural", tip: "Queuing is taken seriously. Join the back; don't push to the front, even if it looks informal." },
      { category: "practical", tip: "All national museums and galleries are free, including the British Museum and Tate Modern." },
      { category: "food", tip: "Pubs typically stop serving food by 9pm. Arrive before 8pm if you're eating at one." }
    ]
  },
  {
    destination: "Barcelona",
    aliases: ["barcelona, spain"],
    tips: [
      { category: "cultural", tip: "Dinner rarely starts before 9pm. Restaurants filling up at 10pm is completely normal." },
      { category: "cultural", tip: "Many locals speak Catalan as a first language — a small greeting in Catalan is well received." },
      { category: "transport", tip: "The T-Casual (10-trip card) covers metro, buses, and trams and is the best value for a short stay." },
      { category: "practical", tip: "Keep valuables in a front pocket on Las Ramblas and around Barceloneta beach." },
      { category: "food", tip: "A menú del día at lunch (two courses, bread, drink) is the city's best-value meal — usually 12–15€." }
    ]
  },
  {
    destination: "Amsterdam",
    aliases: ["amsterdam, netherlands"],
    tips: [
      { category: "transport", tip: "Bikes have absolute right of way. Cross cycle lanes carefully and always look both ways." },
      { category: "transport", tip: "The GVB day-pass covers trams, buses, and the metro — useful if you're not cycling." },
      { category: "cultural", tip: "Museum reservations are strongly recommended. Walk-up availability at the Rijksmuseum is limited." },
      { category: "practical", tip: "Most transactions are card-only. Some smaller cafes and market stalls are cash-only — carry a little." },
      { category: "food", tip: "Indonesian restaurants (rijsttafel) reflect the city's colonial history and are a genuine local tradition." }
    ]
  },
  {
    destination: "Rome",
    aliases: ["rome, italy"],
    tips: [
      { category: "cultural", tip: "Shoulders and knees must be covered to enter churches, including St Peter's Basilica." },
      { category: "cultural", tip: "Eating or drinking on the steps of historic monuments can result in a fine." },
      { category: "transport", tip: "Walking is often faster than buses for central journeys. Traffic can make routes very slow." },
      { category: "food", tip: "Cappuccino after 11am marks you as a tourist — locals drink it only in the morning." },
      { category: "food", tip: "Standing at the bar in a café is cheaper than sitting at a table — a Roman standard." }
    ]
  },
  {
    destination: "Lisbon",
    aliases: ["lisbon, portugal"],
    tips: [
      { category: "transport", tip: "Tram 28 is scenic but crowded with tourists. Walking the same route is often quicker and more enjoyable." },
      { category: "cultural", tip: "Fado performances are found in dedicated houses in Alfama — booking ahead is recommended." },
      { category: "practical", tip: "The city is hilly. Comfortable shoes make a substantial difference to a full day on foot." },
      { category: "food", tip: "A pastel de nata is best warm, from Pastéis de Belém or a local bakery — not a tourist shop." }
    ]
  },
  {
    destination: "Sydney",
    aliases: ["sydney, australia"],
    tips: [
      { category: "transport", tip: "An Opal card works across trains, buses, ferries, and light rail." },
      { category: "transport", tip: "The ferry from Circular Quay to Manly is one of the best harbour views anywhere, and it uses your Opal card." },
      { category: "practical", tip: "Sun protection is essential even in moderate weather. UV index is high year-round." },
      { category: "food", tip: "Flat whites and long blacks are the standard coffee orders here — ordering an \"Americano\" may get a puzzled look." }
    ]
  },
  {
    destination: "Singapore",
    aliases: ["singapore city"],
    tips: [
      { category: "cultural", tip: "Eating is the city's primary social activity. Hawker centres are not budget options — they are institutions." },
      { category: "transport", tip: "The MRT is clean, reliable, and cheap. It reaches most attractions directly." },
      { category: "practical", tip: "Chewing gum, jaywalking, and eating on the MRT are all fineable offences." },
      { category: "food", tip: "Arrive at hawker centres before noon — popular stalls often sell out by 1pm." }
    ]
  }
];
