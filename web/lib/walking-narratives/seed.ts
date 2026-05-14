import type { WalkingNarrative } from "@/types/walking-narrative";

/** Bump when any stop, passage, or narrative is added, removed, or changed. */
export const WALKING_NARRATIVES_SEED_VERSION = "1.0.0";

export const walkingNarrativesSeed: WalkingNarrative[] = [
  // -------------------------------------------------------------------------
  // Athens — the old city on foot
  // -------------------------------------------------------------------------
  {
    place: "Athens",
    aliases: ["athens, greece", "athina"],
    title: "Athens: the layers beneath",
    intro: "A walk through central Athens passes two and a half thousand years in the space of a mile.",
    durationMinutes: 90,
    stops: [
      {
        id: "athens-1",
        name: "Monastiraki Square",
        type: "approach",
        passage: "Monastiraki is the loudest entry point into old Athens — flea market stalls, exhaust fumes, and the unexpected sight of a Byzantine church wedged between a metro entrance and a souvlaki shop. The mosque standing in the square's centre was built by the Ottomans in the 18th century on the foundations of a much older structure. Below your feet, a Roman bath complex excavated during metro construction now sits in glass beneath the station concourse.",
        lookFor: "Look through the metro entrance glass at the excavated ruins below street level."
      },
      {
        id: "athens-2",
        name: "Hadrian's Library",
        type: "landmark",
        passage: "The long Roman wall running alongside Areos Street is what remains of Hadrian's Library, built around 132 AD. It was not a library in the way we use the word — it was a cultural complex with a garden courtyard, lecture halls, and a room of papyrus scrolls at its centre. The wall is enormous: thick, precise, and made from Pentelic marble quarried from the same mountain that supplied the Parthenon. The Athenians who walked past it the day it opened would have found it overwhelming.",
        lookFor: "The mason's marks still visible on some blocks — each quarry worker had a personal symbol."
      },
      {
        id: "athens-3",
        name: "Ancient Agora entrance",
        type: "history",
        passage: "The path down into the Agora drops below the noise of the city almost immediately. In the fifth century BC this was the centre of Athenian public life: courts, shrines, assembly points, and the stalls of the market running along the edges. Socrates died about two hundred metres from here, in a prison whose location archaeologists identified from a cache of small hemlock-root cups found during excavation. The democracy that sentenced him also met here.",
        lookFor: "The Hephaisteion temple on the rise above the Agora — the best-preserved ancient Greek temple anywhere, largely because it was converted to a church early enough to be maintained."
      },
      {
        id: "athens-4",
        name: "Thission viewpoint",
        type: "viewpoint",
        passage: "From the café terraces along Apostolou Pavlou street, the Acropolis sits directly above you — close enough that you can see individual figures on the Parthenon frieze with binoculars, far enough to read it as architecture rather than ruin. This street was pedestrianised in 2000, creating a three-kilometre uninterrupted path that rings the ancient core of the city. In the evenings, when the stone catches the last light, it turns the colour of honey.",
        lookFor: "The line of the original city wall running along the base of the Acropolis rock — the Themistoklean Wall, rebuilt in thirty days after the Persians burned the city in 480 BC."
      },
      {
        id: "athens-5",
        name: "Acropolis approach — the Propylaia",
        type: "architecture",
        passage: "The Propylaia is the ceremonial gateway to the Acropolis — and it was designed to make you feel small before you reached the Parthenon. The columns narrow slightly as they rise, an optical correction that makes the entrance look taller than it is. As you pass through, the Parthenon snaps into full view in a single moment: that sudden reveal was intentional, not incidental. The architects understood that approach matters as much as arrival.",
        lookFor: "The ceiling of the north wing still shows traces of dark blue paint with gold stars — the original colour scheme of the sacred entrance."
      },
      {
        id: "athens-6",
        name: "The Parthenon",
        type: "mythology",
        passage: "The Parthenon was built between 447 and 432 BC and has been a treasury, a church, a mosque, and a gunpowder store. The statue of Athena that stood inside — twelve metres tall, clad in ivory and gold — disappeared sometime in late antiquity. The building has not been intact for over three hundred years, since the Venetian bombardment of 1687 detonated the Ottoman gunpowder stored in the nave. What you see is partly reconstruction. The marble dust on your hands is from the Pentelic quarry, the same source as the original blocks, because the restorers used it to patch the joins."
      }
    ]
  },

  // -------------------------------------------------------------------------
  // Acropolis — the hill itself
  // -------------------------------------------------------------------------
  {
    place: "Acropolis",
    aliases: ["acropolis of athens", "acropolis hill"],
    title: "The Acropolis: stone and memory",
    intro: "The Acropolis is not a single monument — it is a hill that has been continuously sacred for at least three thousand years.",
    durationMinutes: 60,
    stops: [
      {
        id: "acropolis-1",
        name: "The Sacred Way",
        type: "approach",
        passage: "The path up the south slope follows what was once the Panathenaic Way — the route of the great procession held every four years in Athena's honour. Thousands would walk this route in late summer, bringing offerings, cattle, and the newly woven peplos robe for the goddess's statue. The olive trees on either side of the modern path are descendants of trees that were here when the procession still ran.",
        lookFor: "The cuttings in the rock face — footholds carved to help the ancient procession carry heavy offerings up the steep slope."
      },
      {
        id: "acropolis-2",
        name: "The Beule Gate",
        type: "history",
        passage: "The gate you enter through was built in the 3rd century AD — late Roman, not classical. By then the Acropolis had already been sacred for two thousand years. The Romans built this gate partly for prestige and partly because the Herulian sack of 267 AD had left the city badly damaged. Beneath it, you are walking on stone that has been walked on continuously for longer than most civilisations have existed.",
        lookFor: "The chariot ruts worn into the stone — evidence of the ancient processional route running directly below the gate."
      },
      {
        id: "acropolis-3",
        name: "The Erechtheion",
        type: "mythology",
        passage: "The Erechtheion was built to house three sacred things at once: the mark left by Poseidon's trident in the bedrock, the tomb of the ancient king Erechtheus, and Athena's olive tree. The Caryatid porch — where columns take the form of standing women — faces the Parthenon directly, as if the two buildings are in conversation. Five of the original Caryatids are in the Acropolis museum; the sixth was removed by Lord Elgin in 1801.",
        lookFor: "The olive tree growing in the north courtyard — a replacement for the one the Persians burned. Pausanias records that the original had regrown a new shoot by the morning after the fire."
      },
      {
        id: "acropolis-4",
        name: "The Parthenon's east end",
        type: "architecture",
        passage: "Stand at the east end of the Parthenon and look along the columns. They appear perfectly straight, but they are not — every column leans very slightly inward, and the stylobate (the platform beneath them) curves upward slightly at the centre. These are deliberate corrections for the way the human eye perceives straight horizontal lines as sagging. The builders knew that a perfectly straight building would look bent, so they built it slightly bent to make it look straight.",
        lookFor: "Hold a straight edge horizontally against the steps — you can see the slight upward curve of the stylobate against the line."
      },
      {
        id: "acropolis-5",
        name: "West terrace viewpoint",
        type: "viewpoint",
        passage: "From the west terrace, Athens spreads below you in every direction — a continuous city of four million people with no visible edge from here. To the south, the Saronic Gulf catches the light on clear days. Directly below, Monastiraki square is visible as a break in the rooflines. The hill you are standing on has been a lookout point since the Mycenaean age. The people who built the first walls here three thousand years ago saw the same horizon.",
        lookFor: "Lycabettus Hill to the northeast — the other great rock of Athens, always visible from the Acropolis, never as famous."
      }
    ]
  },

  // -------------------------------------------------------------------------
  // Ancient Agora — the civic core
  // -------------------------------------------------------------------------
  {
    place: "Ancient Agora",
    aliases: ["agora of athens", "athens agora", "ancient agora of athens"],
    title: "The Agora: where Athens argued",
    intro: "The Agora was the heart of ancient Athens — not a monument but a lived civic space, full of noise and argument and commerce.",
    durationMinutes: 45,
    stops: [
      {
        id: "agora-1",
        name: "Stoa of Attalos",
        type: "landmark",
        passage: "The long two-storey colonnade that faces you as you enter the Agora is a 1950s reconstruction, built using ancient techniques and marble from the original quarry. The original was a gift from King Attalos II of Pergamon around 150 BC — he had studied in Athens and wanted to give something back to the city. The reconstruction was funded by the Rockefeller family. Inside, the Agora museum holds a cup that was found in a drain nearby and is almost certainly the hemlock cup used at Socrates' execution.",
        lookFor: "The original column drums still visible at the base of the reconstruction, darker and smoother than the new marble above them."
      },
      {
        id: "agora-2",
        name: "The Bouleuterion site",
        type: "history",
        passage: "The low rectangular foundation to the west of the Agora marks where the Bouleuterion stood — the meeting hall of the Boule, the five-hundred-member council that ran the day-to-day business of Athenian democracy. The full assembly of ten thousand citizens met in a different building on the Pnyx hill nearby, but the council worked here, every day, preparing business for the assembly to vote on. Democracy was not just voting; it was continuous administrative work, done by ordinary citizens on rotation.",
        lookFor: "The circular tholos just south of it — where fifty councillors lived and ate while on duty, to ensure that Athens was never without a government even for a single night."
      },
      {
        id: "agora-3",
        name: "The Altar of the Twelve Gods",
        type: "mythology",
        passage: "A small fenced enclosure near the railway line marks where the Altar of the Twelve Gods once stood. This was the zero point of Athens — all distances in Attica were measured from here. Suppliants who reached this altar could not be touched. It was a sanctuary within a sanctuary: the Agora itself was sacred space, but this was its most sacred point. The railway cut directly through it in the 19th century. Part of the altar foundation is now under the tracks.",
        lookFor: "The stone marker on the ground showing the location of the altar and its relationship to the rail line above."
      },
      {
        id: "agora-4",
        name: "Hephaisteion (Temple of Hephaestus)",
        type: "architecture",
        passage: "The Doric temple on the hill above the Agora is the Hephaisteion — dedicated to the god of fire and metalwork, patron of craftsmen. It survives almost intact because it was converted to a Christian church in the 7th century AD, which meant it was maintained rather than quarried for building material. The nave was altered, the cult statue removed, the orientation reversed. The temple has been in continuous use as a sacred space — first for Hephaestus, then for St. George — for over two thousand years.",
        lookFor: "The frieze on the east end still shows traces of paint in the carved metopes — a reminder that ancient temples were not the white marble they appear to be today."
      }
    ]
  }
];
