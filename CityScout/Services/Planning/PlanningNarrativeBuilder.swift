import Foundation

struct PlanningNarrativeBuilder {
    func narrative(
        for itinerary: LocalPlannedItinerary,
        preferences: Set<String> = []
    ) -> String? {
        let allItems = itinerary.sections.flatMap(\.items)
        guard allItems.isEmpty == false else {
            return nil
        }

        let mappedCount = allItems.filter { $0.mappingStatus == .matchedPOI }.count
        let fallbackCount = allItems.count - mappedCount
        let density = allItems.count

        let tone = dayTone(
            density: density,
            preferences: preferences,
            hasEvening: itinerary.evening.items.isEmpty == false
        )
        let categoryStory = categoryStory(for: allItems, preferences: preferences)
        let qualityStory = qualityStory(
            mappedCount: mappedCount,
            fallbackCount: fallbackCount,
            totalCount: allItems.count
        )

        return "\(tone) \(categoryStory) \(qualityStory)"
    }

    private func dayTone(
        density: Int,
        preferences: Set<String>,
        hasEvening: Bool
    ) -> String {
        if preferences.contains("relaxed") || density <= 3 {
            return "A relaxed day in your city."
        }

        if preferences.contains("foodfocused") || preferences.contains("food-focused") {
            return "A food-led day built around your saved spots."
        }

        if preferences.contains("sightseeing") {
            return hasEvening ? "A sightseeing-heavy day with a steady evening finish." : "A sightseeing-focused day with an easy pace."
        }

        if hasEvening {
            return "A balanced day that carries through into the evening."
        }

        return "A balanced day built around your saved highlights."
    }

    private func categoryStory(
        for items: [PlannedActivity],
        preferences: Set<String>
    ) -> String {
        let lowercasedTitles = items.map(\.title).map {
            $0.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        }

        let hasCoffee = lowercasedTitles.contains { $0.contains("cafe") || $0.contains("coffee") || $0.contains("bakery") }
        let hasCulture = lowercasedTitles.contains { $0.contains("museum") || $0.contains("gallery") || $0.contains("cathedral") || $0.contains("louvre") }
        let hasEvening = lowercasedTitles.contains { $0.contains("bar") || $0.contains("dinner") || $0.contains("night") || $0.contains("restaurant") }

        if preferences.contains("nightout") || preferences.contains("night out") || hasEvening && hasCulture {
            return "It leans into culture by day and a stronger evening finish."
        }

        if preferences.contains("cafes") || hasCoffee && hasCulture {
            return "It combines coffee stops with culture and easy wandering."
        }

        if preferences.contains("foodfocused") || preferences.contains("food-focused") || hasCoffee && hasEvening {
            return "It mixes cafés, good food, and a gentle evening rhythm."
        }

        switch (hasCoffee, hasCulture, hasEvening) {
        case (true, true, true):
            return "It threads coffee, culture, and an easy evening together."
        case (true, true, false):
            return "It keeps the day anchored around coffee and culture."
        case (false, true, true):
            return "It pairs culture with a stronger evening finish."
        case (true, false, true):
            return "It balances food and drink with a relaxed pace."
        case (false, true, false):
            return "It stays focused on sightseeing and culture."
        case (false, false, true):
            return "It keeps the emphasis on food and evening plans."
        case (true, false, false):
            return "It favors coffee stops and easy wandering."
        default:
            return "It draws from your saved highlights without overfilling the day."
        }
    }

    private func qualityStory(
        mappedCount: Int,
        fallbackCount: Int,
        totalCount: Int
    ) -> String {
        if fallbackCount == 0 {
            return "Most stops are known mapped places, so the day should feel dependable on the map."
        }

        if mappedCount == 0 {
            return "This plan stays flexible because it relies on general saved ideas rather than mapped stops."
        }

        if fallbackCount >= max(2, totalCount / 2) {
            return "It mixes mapped stops with a few flexible suggestions where the app has lighter local detail."
        }

        return "Most of the day is map-ready, with a small number of flexible fallback ideas."
    }
}
