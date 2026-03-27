import Foundation

enum ItineraryPlaceMatcher {
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
            let normalizedName = normalize(poi.name)
            let normalizedDescription = normalize(poi.shortDescription)
            let nameTokens = significantTokens(in: normalizedName)

            let score: Int?
            if normalizedActivity == normalizedName {
                score = 1_000
            } else if normalizedActivity.contains(normalizedName) || normalizedName.contains(normalizedActivity) {
                score = nameTokens.isEmpty ? nil : 900 + nameTokens.count
            } else {
                let overlappingNameTokens = activityTokens.intersection(nameTokens)
                let allActivityTokensMatchName = overlappingNameTokens.count == activityTokens.count
                let allNameTokensMatchActivity = overlappingNameTokens.count == nameTokens.count

                if overlappingNameTokens.count >= 2 && (allActivityTokensMatchName || allNameTokensMatchActivity) {
                    score = 800 + overlappingNameTokens.count
                } else if overlappingNameTokens.count >= 2 && normalizedDescription.contains(normalizedActivity) {
                    score = 700 + overlappingNameTokens.count
                } else {
                    score = nil
                }
            }

            guard let score else { continue }

            if let bestMatch, bestMatch.score >= score {
                continue
            }

            bestMatch = (poi, score)
        }

        return bestMatch?.poi
    }

    private static func normalize(_ text: String) -> String {
        let folded = text
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

    private static func significantTokens(in normalizedText: String) -> Set<String> {
        Set(
            normalizedText
                .split(separator: " ")
                .map(String.init)
                .filter { $0.count >= 3 }
        )
    }
}
