# CityScout

CityScout is an AI-powered, city-first travel companion built with **SwiftUI**, **SwiftData**, and a **FastAPI + OpenAI backend**.

It helps travellers learn, explore, plan, and navigate new destinations with confidence — before and during a trip.

---

## 🌍 City-First Experience

CityScout is structured around destinations.

On first launch:
1. Users complete a lightweight onboarding flow
2. Select a destination
3. Access a fully scoped experience including:
   - 📚 Lessons
   - 💾 Phrasebook
   - 🌐 Translate
   - 🧭 Explore
   - 🗺 Map
   - 🔍 Search
   - 🧠 Plan (AI itinerary)

Users can switch cities at any time.

---

## ✨ Features

### 📚 Lessons
- Micro-lessons grouped by real-world travel situations
- Structured per city (Café, Getting Around, Hotel, etc.)
- JSON seed-based content packs

### 💾 Phrasebook
- Save useful phrases
- Destination-scoped storage
- Recently practiced tracking
- Search support

### 🌐 Translate
- On-device translation (Apple frameworks)
- Accessible and fast

### 🧭 Explore
- Category-based discovery (Food, Cafés, Sights, etc.)
- Top Picks per category
- Save directly to Map

### 🗺 Map
- Category-aware annotations
- Saved places grouped by category
- Long-press to add locations
- Open in Apple Maps

### 🔍 Search
- Search across POIs and saved places
- Destination-scoped results

### 🧠 Plan (AI Itinerary)
- Generate daily itineraries using AI
- Morning / Afternoon / Evening structure
- Save individual activities
- Save entire itinerary in one tap ("Save All")

---

## 🤖 AI Architecture

- iOS app communicates with a **FastAPI backend**
- Backend securely integrates with OpenAI (no API keys in app)
- Structured JSON itinerary generation
- Fallback logic ensures reliability if AI is unavailable

---

## 🧪 Testing & Reliability

- Backend API tests using **pytest**
- Coverage includes:
  - `/health` endpoint
  - `/plan-itinerary` endpoint
  - request validation and fallback behaviour

---

## ⚙️ Backend Setup

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

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

(Additional European capitals included via seed packs.)

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
│   ├── Map/
│   ├── Search/
│   └── Plan/
├── Models/
├── Services/
├── Resources/
│   └── SeedContent/
└── Core/
```

### Key Concepts

- SwiftData models for Trip, Phrase, SavedPhrase, SavedPlace
- Destination-scoped queries
- Idempotent seed import
- Offline-first design
- Clean separation between app and AI backend

---

## 🚀 Getting Started

1. Open `CityScout.xcodeproj` in Xcode
2. Select an iOS Simulator
3. Build and run

To reset data:
- Delete the app from the simulator

---

## 🧪 CI

GitHub Actions builds and tests the app on push.

---

## 🗺 Roadmap

### V1 (Complete)
- City-first navigation
- Explore + Map + Search
- Phrasebook + Translation

### V2
- Improved itinerary intelligence
- Auto-categorisation of AI activities
- Map + itinerary integration

### V3
- Booking integrations (hotels, restaurants, experiences)
- AI travel assistant (multi-turn)
- Full trip management

---

CityScout is designed as a scalable travel platform — starting with learning and planning, and evolving into a full AI-powered travel companion.

## 📜 License

This project is proprietary and not open source.

© 2026 Tim Finch. All rights reserved.
