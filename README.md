# CityScout

CityScout is a lightweight iOS travel companion app built with **SwiftUI** and **SwiftData**.

It helps travellers quickly learn essential local phrases, explore city-specific micro-lessons, and build a personalised phrasebook before and during a trip.

Currently seeded with:
- 🇪🇸 Barcelona (Spanish)
- 🇫🇷 Paris (French)

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