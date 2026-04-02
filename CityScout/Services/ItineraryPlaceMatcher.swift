import Foundation

enum ItineraryPlaceMatcher {
    private static let minimumConfidenceScore = 700

    static func match(destinationName: String, activityText: String) -> PointOfInterest? {
        let normalizedActivity = normalize(activityText)
        guard normalizedActivity.isEmpty == false else {
            return nil
        }

        let activityTokens = significantTokens(in: normalizedActivity)
        guard activityTokens.isEmpty == false else {
            return nil
        }

        let pois = PointOfInterest.pois(in: destinationName)

        var bestMatch: (poi: PointOfInterest, score: Int)?

        for poi in pois {
            let score = scoreMatch(
                poi: poi,
                normalizedActivity: normalizedActivity,
                activityTokens: activityTokens
            )

            guard let score else { continue }
            guard score >= minimumConfidenceScore else { continue }

            if let bestMatch, bestMatch.score >= score {
                continue
            }

            bestMatch = (poi, score)
        }

        return bestMatch?.poi
    }

    private static func scoreMatch(
        poi: PointOfInterest,
        normalizedActivity: String,
        activityTokens: Set<String>
    ) -> Int? {
        let normalizedName = normalize(poi.name)
        let normalizedDescription = normalize(poi.shortDescription)
        let nameTokens = significantTokens(in: normalizedName)
        let descriptionTokens = significantTokens(in: normalizedDescription)

        guard nameTokens.isEmpty == false else {
            return nil
        }

        if normalizedActivity == normalizedName {
            return 1_000
        }

        let combinedTokens = nameTokens.union(descriptionTokens)

        if phraseContainsWholePhrase(normalizedActivity, phrase: normalizedName) {
            return 940 + min(nameTokens.count, 5)
        }

        if activityTokens == nameTokens {
            return 920 + min(nameTokens.count, 5)
        }

        let overlappingNameTokens = activityTokens.intersection(nameTokens)
        let overlappingDescriptionTokens = activityTokens.intersection(descriptionTokens)
        let unknownActivityTokens = activityTokens.subtracting(combinedTokens)

        if overlappingNameTokens.count == nameTokens.count,
           overlappingNameTokens.count >= 2,
           unknownActivityTokens.count <= 1 {
            return 880 + overlappingNameTokens.count - unknownActivityTokens.count
        }

        if overlappingNameTokens.count >= 2,
           overlappingNameTokens.count == activityTokens.count,
           activityTokens.count >= 2 {
            return 840 + overlappingNameTokens.count
        }

        if overlappingNameTokens.count >= 2,
           overlappingDescriptionTokens.isEmpty == false,
           unknownActivityTokens.count == 0 {
            return 780 + overlappingNameTokens.count + overlappingDescriptionTokens.count
        }

        if nameTokens.count == 1,
           let distinctiveToken = nameTokens.first,
           distinctiveToken.count >= 5,
           overlappingNameTokens.contains(distinctiveToken),
           unknownActivityTokens.count <= 1 {
            return 760 - unknownActivityTokens.count
        }

        return nil
    }

    private static func normalize(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            return ""
        }

        let folded = trimmed
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .replacingOccurrences(
                of: #"[^\p{L}\p{N}]+"#,
                with: " ",
                options: .regularExpression
            )

        return folded
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.isEmpty == false }
                .joined(separator: " ")
    }

    private static func phraseContainsWholePhrase(_ text: String, phrase: String) -> Bool {
        guard text.isEmpty == false, phrase.isEmpty == false else {
            return false
        }

        return (" \(text) ").contains(" \(phrase) ")
    }

    private static func significantTokens(in normalizedText: String) -> Set<String> {
        Set(
            normalizedText
                .split(separator: " ")
                .map(String.init)
                .filter { token in
                    token.count >= 3 && genericTokens.contains(token) == false
                }
        )
    }

    private static let genericTokens: Set<String> = [
        "and",
        "afternoon",
        "area",
        "around",
        "at",
        "bar",
        "break",
        "cafe",
        "city",
        "dinner",
        "district",
        "drink",
        "drinks",
        "eat",
        "evening",
        "explore",
        "food",
        "for",
        "from",
        "lunch",
        "market",
        "museum",
        "night",
        "morning",
        "restaurant",
        "see",
        "shopping",
        "sight",
        "sights",
        "spot",
        "stop",
        "tour",
        "visit",
        "walk"
    ]
}
