import type { PlaceHistoryMythology } from "@/types/history-mythology";

/** Bump when any story, headline, or reading entry is added, removed, or changed. */
export const HISTORY_MYTHOLOGY_SEED_VERSION = "1.1.0";

export const historyMythologySeed: PlaceHistoryMythology[] = [
  // -------------------------------------------------------------------------
  // Athens
  // -------------------------------------------------------------------------
  {
    place: "Athens",
    aliases: ["athens, greece", "athina"],
    stories: [
      {
        category: "mythology",
        headline: "The contest for a city",
        body: "Athena and Poseidon both wanted the city. Poseidon struck the rock of the Acropolis and seawater gushed out — impressive, but useless inland. Athena pressed her spear into the ground and an olive tree grew. The citizens chose the olive, and the city took her name. The tree the goddess planted was said to still grow on the Acropolis into Roman times."
      },
      {
        category: "history",
        headline: "Democracy's first draft",
        body: "In 507 BC, the reformer Cleisthenes broke the grip of aristocratic clans by reorganising citizens into ten new tribes based on geography rather than bloodline. He called the new system demokratia — the power of the people. It was messy, contentious, and constantly argued over. It was also the first time a government was openly designed to be temporary and accountable."
      },
      {
        category: "culture",
        headline: "The city that argued itself into greatness",
        body: "Athens in the fifth century BC was not a comfortable place. Socrates was tried and executed for asking too many questions. Plays were staged that mocked politicians by name. Comedians performed in front of the politicians they were mocking. The agora was a marketplace, but also a permanent public argument. Athens didn't produce great thinking despite its disorder — it produced great thinking because of it."
      }
    ],
    reading: [
      { title: "The Peloponnesian War", author: "Thucydides", note: "The original account of Athens at its height and its fall — written by someone who was there." },
      { title: "The Histories", author: "Herodotus", note: "The wider Greek world through a storyteller's eye." },
      { title: "The Greeks", author: "H.D.F. Kitto", note: "Probably the best single-volume introduction to what Athens was actually like to live in." }
    ]
  },

  // -------------------------------------------------------------------------
  // Acropolis
  // -------------------------------------------------------------------------
  {
    place: "Acropolis",
    aliases: ["acropolis of athens", "acropolis hill"],
    stories: [
      {
        category: "landmark",
        headline: "A hill before it was a monument",
        body: "People lived on the Acropolis rock for millennia before the Parthenon existed. Mycenaean kings built a palace here around 1400 BC. After them came the tyrants, then the democracy. Each era added to or tore down what the last had built. The Parthenon was constructed in the 440s BC — not because Athens was at peace, but precisely because it had just survived the Persian Wars and wanted to say so in stone."
      },
      {
        category: "mythology",
        headline: "Where Athena kept her olive tree",
        body: "The north side of the Acropolis holds the Erechtheion, built to enclose three sacred things at once: the marks left by Poseidon's trident, the tomb of the ancient king Erechtheus, and the stump of Athena's original olive tree. The Persians burned the first tree in 480 BC. According to Herodotus, it had grown a new shoot by the next morning."
      },
      {
        category: "history",
        headline: "A temple repurposed five times",
        body: "The Parthenon has been a treasury, a Christian church dedicated to the Virgin Mary, and a mosque with a minaret. In 1687 the Venetians fired a mortar into it while it was being used as a gunpowder store by the Ottomans. The resulting explosion destroyed most of the roof and interior. Much of what you see today is 20th-century reconstruction."
      }
    ],
    reading: [
      { title: "The Parthenon Enigma", author: "Joan Breton Connelly", note: "A reassessment of what the Parthenon sculptures actually meant to the people who made them." },
      { title: "Acropolis", author: "Vincent Scully", note: "Short and architectural — on how the buildings shape each other and the landscape." }
    ]
  },

  // -------------------------------------------------------------------------
  // Ancient Agora
  // -------------------------------------------------------------------------
  {
    place: "Ancient Agora",
    aliases: ["agora of athens", "athens agora", "ancient agora of athens"],
    stories: [
      {
        category: "landmark",
        headline: "The space where the city thought",
        body: "The Agora was not a quiet place. Merchants shouted, magistrates held hearings, and philosophers walked in colonnades talking to anyone who would listen. Socrates did most of his philosophising here — not in a school but among the noise. Archaeologists have found the prison where he was held, and the cup thought to have held the hemlock. The Agora was also where ostracism votes were counted: citizens scratched names onto shards of pottery, and whoever had the most scratched against them was exiled for ten years."
      },
      {
        category: "mythology",
        headline: "Theseus and the bones of a hero",
        body: "Theseus — the king who slew the Minotaur and brought the Athenians home from Crete — was venerated in the Agora. After the Persian Wars, the Athenian general Cimon claimed to have found Theseus's bones on the island of Skyros and brought them back. Whether or not the bones were real, the shrine built for them in the Agora was used as a sanctuary for slaves and the poor seeking protection from their masters. Even a mythological king could be given a practical job."
      },
      {
        category: "history",
        headline: "The Stoa of Attalos, rebuilt",
        body: "The long colonnaded building that anchors the modern Agora is a 1950s reconstruction, funded by the Rockefeller family and built using ancient techniques and Pentelic marble from the same quarry as the originals. It now houses the Agora museum. The original was built around 150 BC by King Attalos II of Pergamon, who had studied in Athens and wanted to give the city something back."
      }
    ],
    reading: [
      { title: "The Athenian Agora: A Guide to the Excavation and Museum", author: "American School of Classical Studies", note: "The excavation authority's own guide — thorough and specific." }
    ]
  },

  // -------------------------------------------------------------------------
  // Plaka
  // -------------------------------------------------------------------------
  {
    place: "Plaka",
    aliases: ["plaka, athens", "plaka neighbourhood", "plaka neighborhood"],
    stories: [
      {
        category: "landmark",
        headline: "A neighbourhood built on ruins",
        body: "Plaka is the oldest continuously inhabited neighbourhood in Athens, a district of neoclassical houses and Byzantine churches layered directly over the ancient residential quarters of the city. The streets follow no grid because they follow the ancient paths: the lanes that wound between workshops and houses two and a half thousand years ago are the same lanes tourists navigate today. Beneath almost every basement, excavations have turned up classical-era pottery, coins, or household objects."
      },
      {
        category: "history",
        headline: "The neighbourhood that survived everything",
        body: "Plaka endured the Ottoman occupation, the Greek War of Independence, and rapid 20th-century development relatively intact — largely because it was considered too old and chaotic to modernise efficiently. In the 1970s, when parts were threatened with demolition, archaeologists and preservationists argued successfully for its protection. The neighbourhood was pedestrianised and restored in the 1980s. What looks organic and ancient is partly the result of a very deliberate decision to leave it that way."
      },
      {
        category: "mythology",
        headline: "The Tower of the Winds",
        body: "At the edge of Plaka stands the Tower of the Winds, an octagonal marble structure built around 50 BC by the astronomer Andronikos. Each of its eight faces is carved with a figure representing a different wind — Boreas (north), Kaikias (northeast), Apeliotes (east), Euros (southeast), Notos (south), Lips (southwest), Zephyros (west), and Skiron (northwest). It housed a water clock that kept time using a hydraulic system. The Ottomans later used it as a tekke for whirling dervishes. The wind figures are still there, still facing their directions."
      }
    ],
    reading: [
      { title: "Athens: A Cultural and Literary History", author: "Michael Llewellyn Smith", note: "The neighbourhood histories are specific and readable — Plaka features throughout." }
    ]
  },

  // -------------------------------------------------------------------------
  // Monastiraki
  // -------------------------------------------------------------------------
  {
    place: "Monastiraki",
    aliases: ["monastiraki square", "monastiraki, athens", "monastiraki flea market"],
    stories: [
      {
        category: "landmark",
        headline: "Three thousand years in one square",
        body: "Monastiraki square is one of the densest archaeological collisions in the world. A Roman market (the Roman Agora) sits one hundred metres to the east. Below the metro station, excavated during construction in the 1990s, lies a Roman bath complex now visible through glass beneath the concourse. The mosque in the centre of the square was built in 1759 by the Ottoman governor Tzistarakis, who demolished a column from the Temple of Olympian Zeus to make lime for it — an act for which he was dismissed from office."
      },
      {
        category: "history",
        headline: "The flea market as living archaeology",
        body: "The Monastiraki flea market has been a trading ground since at least the Ottoman period, when the area was full of textile merchants, leather workers, and copper smiths. After Greek independence, it became the place where the dispossessed sold whatever they had. Today it layers antique dealers, vinyl records, military surplus, Byzantine icons, and tourist souvenirs in a way that mirrors exactly how the city has layered itself. On Sunday mornings, the outdoor market expands and the bargaining becomes more serious."
      }
    ]
  },

  // -------------------------------------------------------------------------
  // Lycabettus Hill
  // -------------------------------------------------------------------------
  {
    place: "Lycabettus Hill",
    aliases: ["lycabettus", "lykavittos", "lykavitos hill", "lycabettus", "mount lycabettus"],
    stories: [
      {
        category: "mythology",
        headline: "The hill Athena dropped",
        body: "Mythology records that Lycabettus Hill was created by accident. Athena was carrying a great rock to place on the Acropolis when a crow brought her bad news — the details vary by telling. In her shock, she dropped the rock, and it became Lycabettus. The Acropolis was already lower than planned, which is why it looks the way it does. The crow, for its trouble, was punished by having its feathers turned from white to black — making Lycabettus also the origin story of the crow's colour."
      },
      {
        category: "landmark",
        headline: "The other great hill",
        body: "At 278 metres, Lycabettus is the highest point in Athens and the only major hill in the city not anchored by ancient ruins. The chapel of St. George at the summit was built in the 19th century and is still active. The funicular railway that carries visitors up was constructed in 1965 and runs through a tunnel cut into the rock. On clear days you can see the Saronic Gulf, the Parthenon directly opposite, and on very clear days, as far as the Peloponnese. Athenians use the hill for evening walks in a way that tourists rarely do."
      }
    ]
  },

  // -------------------------------------------------------------------------
  // Kerameikos
  // -------------------------------------------------------------------------
  {
    place: "Kerameikos",
    aliases: ["kerameikos, athens", "keramikos", "ancient kerameikos", "ceramicus"],
    stories: [
      {
        category: "history",
        headline: "The cemetery where Athens remembers its dead",
        body: "Kerameikos was Athens' main burial ground from the 12th century BC through the Roman period — over a thousand years of continuous use. The city's most important citizens were buried here: philosophers, generals, politicians, the anonymous dead of the great battles. The grave monuments lining the Street of the Tombs are some of the finest funerary sculpture from the ancient world. The Sacred Way to Eleusis — the processional road walked by initiates into the Eleusinian Mysteries — began at the Kerameikos gate."
      },
      {
        category: "landmark",
        headline: "Named for the potters",
        body: "The district takes its name from the ancient potters' quarter — keramos means fired clay, and the ceramics of this neighbourhood gave us the English word 'ceramic'. The area was both a workshop district and a cemetery simultaneously, which seems contradictory until you understand ancient Athenian city planning: the dead were buried outside the city walls, and the walls ran through what is now Kerameikos. The Dipylon Gate nearby was the main ceremonial entrance to the city, through which processions, armies, and merchants all passed."
      },
      {
        category: "mythology",
        headline: "The Eleusinian road",
        body: "The Sacred Way began at the Dipylon Gate in Kerameikos and ran fourteen miles to Eleusis, where initiates participated in mysteries dedicated to Demeter and Persephone. The mysteries were among the most closely kept secrets of the ancient world — initiates were forbidden on pain of death from revealing what happened during the rites. We know the route in detail; we know almost nothing about the rituals at the end of it. Cicero called the Eleusinian Mysteries 'the best and most divine thing Athens has ever produced'."
      }
    ],
    reading: [
      { title: "The Eleusinian and Bacchic Mysteries", author: "Thomas Taylor", note: "A scholarly reconstruction of what may have happened at Eleusis, with the usual caveats about the source problem." }
    ]
  },

  // -------------------------------------------------------------------------
  // National Archaeological Museum
  // -------------------------------------------------------------------------
  {
    place: "National Archaeological Museum",
    aliases: ["national museum athens", "archaeological museum athens", "national archaeological museum of athens", "ethnikó archaiologikó mouseío"],
    stories: [
      {
        category: "landmark",
        headline: "The collection that rewrote ancient history",
        body: "The National Archaeological Museum of Athens, opened in 1891, holds one of the most important collections of ancient artefacts in the world. Room by room, it tells the story of Greece from the Neolithic period through to late antiquity — not as a survey but as a series of specific, extraordinary objects. The gold Mask of Agamemnon (almost certainly not Agamemnon's, but found in Mycenae in a shaft grave by Heinrich Schliemann in 1876). The bronze Artemision Poseidon, cast around 460 BC, balanced mid-throw for over two thousand years before being found on the seabed. The Antikythera Mechanism, the world's first known analogue computer, recovered from a shipwreck in 1901."
      },
      {
        category: "history",
        headline: "The Antikythera Mechanism",
        body: "Found in 1901 by sponge divers off the island of Antikythera, the Mechanism is a bronze geared device built around 100 BC that tracked the movements of the sun, moon, and five known planets, predicted solar and lunar eclipses, and displayed the Olympic calendar. It uses differential gearing — a technology not known to have existed until the 1600s. Examination with X-ray tomography in 2006 revealed over 30 interlocking gears and text inscriptions explaining its functions. The device in the museum is the corroded original; reconstructions in the same room show what it likely looked like working."
      },
      {
        category: "mythology",
        headline: "The Thera frescoes",
        body: "Among the less-visited rooms in the museum is a gallery of frescoes excavated from Akrotiri on the island of Thera (Santorini) — a Minoan city buried by volcanic eruption around 1627 BC, preserved in ash like Pompeii. The paintings show blue monkeys, boxing children, antelopes, and a famous Spring Fresco of swallows above red lilies. They were made by people whose civilisation was destroyed before the Parthenon was built. Some scholars believe the Thera eruption contributed to the mythology of Atlantis."
      }
    ],
    reading: [
      { title: "The Antikythera Mechanism: A Calendar Computer from about 80 BC", author: "Derek de Solla Price", note: "The 1974 paper that first established the full complexity of the device." }
    ]
  },

  // -------------------------------------------------------------------------
  // Syntagma
  // -------------------------------------------------------------------------
  {
    place: "Syntagma",
    aliases: ["syntagma square", "syntagma, athens", "constitution square"],
    stories: [
      {
        category: "history",
        headline: "The square named for a forced concession",
        body: "Syntagma means 'constitution'. The square was named in 1843, when King Otto — Bavaria-born ruler of newly independent Greece — was compelled by a military revolt to grant a constitution he had been refusing to issue. The crowd that gathered outside the Royal Palace (now the Parliament building) to demand it was large enough that Otto appeared on the balcony and agreed. The square has been the site of every major political demonstration in Athens since: the events of the 1944 Dekemvriana, the 1973 student uprising, and the austerity protests of 2010–2012 all centred here."
      },
      {
        category: "landmark",
        headline: "The Evzone guard",
        body: "The Tomb of the Unknown Soldier, carved into the Parliament building's retaining wall in 1930, is guarded around the clock by Evzones — soldiers of the Presidential Guard. Their ceremonial uniform, the fustanella, derives from the dress of Greek mountain fighters during the War of Independence: a short pleated kilt, white tights, and shoes with large pompoms. The change of guard every hour on the hour is precise and slow, a deliberate ritual pace that reads as tribute rather than performance."
      }
    ]
  },

  // -------------------------------------------------------------------------
  // Paros
  // -------------------------------------------------------------------------
  {
    place: "Paros",
    aliases: ["paros, greece", "paros island"],
    stories: [
      {
        category: "history",
        headline: "The island that built half of Greece",
        body: "Parian marble is extraordinarily translucent — light passes several centimetres into the stone before being reflected back, which gives finished sculpture an almost skin-like quality. The quarries at Marathi supplied the marble for the Nike of Samothrace, the Venus de Milo, and the Temple of Apollo at Delphi. The island's greatest export was not wine or grain but the stone from which Greece imagined its gods."
      },
      {
        category: "mythology",
        headline: "Archilochus and the god of poetry",
        body: "Paros was home to Archilochus, one of the earliest Greek poets and reportedly the first to use iambic meter — the same rhythm Shakespeare would use two thousand years later. He claimed that the Muses appeared to him in a field and handed him a lyre in exchange for his oxen. He became a soldier, famously threw away his shield to survive a battle, and wrote a poem about it. Later Greeks quoted him alongside Homer."
      },
      {
        category: "culture",
        headline: "Parikia's marble town",
        body: "The old town of Parikia grew around the ruins of a classical temple, building its churches and houses directly into the ancient stones. The cathedral, Ekatontapiliani — the Church of a Hundred Doors — has been a place of worship continuously since the 4th century AD. One of the doors is said to be hidden; when it is found, Greece will reclaim Constantinople."
      }
    ],
    reading: [
      { title: "The Poems of Archilochus", author: "Archilochus (trans. Guy Davenport)", note: "Fragments only — but the soldier-poet's voice comes through vividly across the gap." }
    ]
  },

  // -------------------------------------------------------------------------
  // Naxos
  // -------------------------------------------------------------------------
  {
    place: "Naxos",
    aliases: ["naxos, greece", "naxos island"],
    stories: [
      {
        category: "mythology",
        headline: "Where Theseus left Ariadne",
        body: "The standard myth says Theseus abandoned Ariadne on Naxos as he sailed home from Crete. One version says she was sleeping and he simply left. Another says a god told him to — Dionysus wanted her for himself. In the Dionysus version this ends happily; he arrives on the beach, marries her, and gives her a crown of stars that can still be seen in the sky as the Corona Borealis. In the other versions, she dies on the island, or becomes a goddess, or both."
      },
      {
        category: "history",
        headline: "The unfinished colossi",
        body: "In the 6th century BC, Naxian sculptors began carving enormous statues — kouroi — from the local marble and shipping them across the Aegean to sanctuaries at Delos and Delphi. Two were never finished and were left in the quarries, still attached to the bedrock. They lie in the countryside outside Melanes, slightly over ten metres long, their faces looking upward at the sky as if asleep. The reason they were abandoned is unknown."
      },
      {
        category: "mythology",
        headline: "The island of Dionysus",
        body: "Naxos claimed to be the birthplace of Dionysus — or at least the island where he grew up, hidden from Hera in a cave on Mount Zas. The mountain still bears the name. Naxian wine was considered among the best in antiquity, and the island's festivals for Dionysus were reportedly more elaborate and longer than those anywhere else in the Aegean."
      }
    ],
    reading: [
      { title: "The Metamorphoses", author: "Ovid", note: "Book VIII covers Ariadne's crown; Ovid handles the mythology with warmth and wit." },
      { title: "The Naxos Mystery", author: "Various archaeological reports", note: "The scholarly literature on the kouros quarries is worth reading if you visit Melanes." }
    ]
  },

  // -------------------------------------------------------------------------
  // Marathon
  // -------------------------------------------------------------------------
  {
    place: "Marathon",
    aliases: ["marathon, greece", "marathon plain", "battle of marathon"],
    stories: [
      {
        category: "history",
        headline: "The day that changed everything",
        body: "In 490 BC, a Persian army landed on the plain of Marathon with a force that ancient sources estimate at around 25,000 — though modern historians think the number lower. The Athenian army, outnumbered and without Spartan support, chose to attack rather than wait. They ran the last stretch of the charge, which reduced the time the Persian archers had to fire. The Persians broke. Around 6,400 Persians died; the Athenians lost 192. The Athenian dead were buried where they fell in a mound — the Soros — that is still visible on the plain today."
      },
      {
        category: "history",
        headline: "The runner who may not have run",
        body: "The story of Pheidippides running from Marathon to Athens to announce the victory — collapsing and dying after the word 'We have won' — appears in Plutarch, written six centuries after the battle. Herodotus, who wrote within living memory, describes a runner sent from Athens to Sparta before the battle to ask for help. The two stories were conflated over time, and the 26-mile race we still run today was invented at the 1896 Athens Olympics to commemorate a journey that probably never happened."
      },
      {
        category: "mythology",
        headline: "Pan on the battlefield",
        body: "Herodotus records that the runner Pheidippides, on his way to Sparta, encountered the god Pan in the mountains of Arcadia. Pan asked why the Athenians didn't honour him — he was well-disposed toward them, after all. After the battle, the Athenians established an annual sacrifice to Pan and built him a shrine beneath the Acropolis in gratitude, apparently for the mass panic he was said to have sent through the Persian ranks."
      }
    ],
    reading: [
      { title: "Persian Fire", author: "Tom Holland", note: "A gripping narrative account of the Persian Wars — Marathon gets the weight it deserves." },
      { title: "The Histories, Book VI", author: "Herodotus", note: "The primary source — precise, curious, and occasionally gossipy about the commanders involved." }
    ]
  }
];
