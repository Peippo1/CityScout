import Foundation

enum ItineraryCategoryInference {
    private static let categoryKeywords: [(category: POICategory, keywords: [String])] = [
        (.cafes, ["coffee", "café", "cafe", "espresso", "latte", "cappuccino", "bakery"]),
        (.food, ["restaurant", "lunch", "dinner", "brunch", "eat", "meal", "taverna", "bistro"]),
        (.sights, ["museum", "gallery", "cathedral", "church", "tower", "palace", "park", "square", "monument", "landmark"]),
        (.shopping, ["shop", "shopping", "market", "boutique", "mall"]),
        (.nightlife, ["bar", "club", "cocktail", "wine", "nightlife", "pub"])
    ]

    static func inferCategory(from activity: String) -> POICategory? {
        let normalizedActivity = activity
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)

        guard normalizedActivity.isEmpty == false else {
            return nil
        }

        for entry in categoryKeywords {
            if entry.keywords.contains(where: { normalizedActivity.contains($0) }) {
                return entry.category
            }
        }

        return nil
    }
}
