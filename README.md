# CityScout

CityScout is a lightweight iOS travel companion app built with **SwiftUI** and **SwiftData**.

It helps travellers quickly learn essential local phrases, explore city-specific micro-lessons, and build a personalised phrasebook before and during a trip.

Currently seeded with:
- 🇪🇸 Barcelona (Spanish)
- 🇫🇷 Paris (French)
- 🇬🇷 Athens (Greek)
- 🇮🇹 Rome (Italian)
- 🇫🇮 Helsinki (Finnish)
- 🇩🇰 Copenhagen (Danish)
- 🇵🇹 Lisbon (Portuguese)

Designed with scalability in mind, CityScout uses a feature-first architecture and seed-based content packs to support rapid expansion to new destinations.

---

## ✨ Features

- 📚 Micro-lessons grouped by real-world situations (Café, Metro, Hotel, etc.)
- 💾 Save phrases to a personalised Phrasebook
- 🔁 Recently Practiced tracking
- 🌍 Multi-destination support
- 🧱 JSON-based seed packs for easy expansion
- ⚡ Built entirely with SwiftUI + SwiftData

---

## 🏗 Architecture

Feature-first structure:

```text
CityScout/
├── App/
├── Features/
│   ├── Lessons/
│   ├── Phrasebook/
│   ├── Translate/
│   ├── Explore/
│   └── Onboarding/
├── Models/
├── Services/
├── Resources/
│   └── SeedContent/
└── Core/
```

### Key Concepts

- **SwiftData Models** for Trip, Situation, Phrase, SavedPhrase
- **Idempotent seed import** per destination
- **Predicate-safe SwiftData queries** (ID-based filtering)
- Debug utilities isolated to `#if DEBUG`

---

## 🚀 Getting Started

1. Open `CityScout.xcodeproj` in Xcode.
2. Select an iOS Simulator.
3. Build and run the `CityScout` target.

To reset seed data in development:
- Use the debug reset action (if enabled)
- Or delete the app from the simulator

---

## 🧪 CI

GitHub Actions builds and tests the app on push to `dev`.

---

## 🗺 Roadmap

- Search within Phrasebook
- Audio pronunciation support
- AI-generated city packs
- Map integration
- On-device translation tools
- App Store release
# CityScout

CityScout is a city-first iOS travel companion built with **SwiftUI** and **SwiftData**.

It helps travellers prepare for trips by learning essential phrases, exploring key landmarks, saving favourite places on a map, and organising everything by destination.

---

## 🌍 City-First Experience

CityScout is structured around destinations.

On first launch:
1. Users see a lightweight onboarding flow.
2. They select the city they’re travelling to.
3. The app presents a destination-scoped experience including:
   - 📚 Lessons
   - 💾 Phrasebook
   - 🌐 Translate
   - 🧭 Explore
   - 🗺 Map

Users can change destination at any time via the "Change City" action.

---

## ✨ Features

### 📚 Lessons
- Micro-lessons grouped by real-world travel situations
- Structured per city (Café, Getting Around, Hotel, etc.)
- Seed-based content packs (JSON driven)

### 💾 Phrasebook
- Save useful phrases
- Destination-scoped storage
- Recently practiced tracking
- Search support

### 🌐 Translate
- On-device translation tools (Apple frameworks)
- Clean, accessible UI

### 🧭 Explore
- Tile-based city exploration
- Key points of interest per destination
- Save locations directly to Map

### 🗺 Map
- Long-press to save places
- Destination-scoped saved places
- Open in Apple Maps
- Managed list of saved locations

---

## 🏙 Current Destinations

Seeded cities include:

- 🇪🇸 Barcelona (Spanish)
- 🇫🇷 Paris (French)
- 🇬🇷 Athens (Greek)
- 🇮🇹 Rome (Italian)
- 🇫🇮 Helsinki (Finnish)
- 🇩🇰 Copenhagen (Danish)
- 🇵🇹 Lisbon (Portuguese)

Each city includes 15 essential travel phrases structured across practical situations.

---

## 🏗 Architecture

Feature-first structure:

```text
CityScout/
├── App/
├── Features/
│   ├── Onboarding/
│   ├── Trips/
│   ├── Lessons/
│   ├── Phrasebook/
│   ├── Translate/
│   ├── Explore/
│   └── Map/
├── Models/
├── Services/
├── Resources/
│   └── SeedContent/
└── Core/
```

### Key Concepts

- **SwiftData models** for Trip, Situation, Phrase, SavedPhrase, SavedPlace
- **Destination-scoped queries** for clean data separation
- **Idempotent seed import** per destination
- **Predicate-safe SwiftData filtering (ID/scalar based)**
- **Offline-first design**
- Debug utilities isolated to `#if DEBUG`

---

## 🚀 Getting Started

1. Open `CityScout.xcodeproj` in Xcode.
2. Select an iOS Simulator.
3. Build and run the `CityScout` target.

To reset seed data during development:
- Delete the app from the simulator
- Or use debug reset utilities (if enabled)

---

## 🧪 CI

GitHub Actions builds and tests the app on push to `dev`.

CI verifies:
- Project builds successfully
- SwiftData schema compiles
- Seed importer idempotency tests pass

---

## 🗺 Roadmap

### V1 (Offline Travel Companion)
- City-first navigation
- Destination-scoped phrase learning
- Saved places map
- On-device translation
- Accessibility polish

### V2
- Audio pronunciation
- More cities via seed packs
- Improved map interactions

### V3
- AI-assisted city guide
- Voice tour mode
- Dynamic content generation
- App Store release

---

CityScout is designed to scale cleanly across destinations while maintaining strong architectural guardrails and test coverage.