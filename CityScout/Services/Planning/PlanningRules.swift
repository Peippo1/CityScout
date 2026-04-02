import Foundation

enum PlanningReason: String, Hashable {
    case goodMorningFit
    case goodAfternoonFit
    case goodEveningFit
    case matchesPreferences
    case mappedPlace
    case nearAnotherStop
    case alreadyVisited
    case previouslySkipped
    case fallbackSuggestion
    case preservesCurrentPlan
    case improvesWeakStop
    case balancesTheDay
    case keepsEveningSpace
    case repeatedCategory
}

enum PlanningRules {
    enum Weights {
        static let timeOfDayFit = 2
        static let preferenceMatch = 3
        static let mappedPlace = 2
        static let nearbyStop = 2
        static let visitedPenalty = -5
        static let skippedPenalty = -4
        static let fallbackRoutePenalty = -1
        static let repeatedCategoryPenalty = -1
        static let preserveCurrentPlan = 2
        static let weakReplacementThreshold = 4
        static let lowQualityThreshold = 2
    }

    static func sectionReason(for section: TimeOfDayTag) -> PlanningReason {
        switch section {
        case .morning:
            return .goodMorningFit
        case .afternoon:
            return .goodAfternoonFit
        case .evening:
            return .goodEveningFit
        case .anytime:
            return .balancesTheDay
        }
    }

    static func timeOfDayScore(
        candidate: PlanningCandidate,
        section: TimeOfDayTag
    ) -> (score: Int, reason: PlanningReason?) {
        guard candidate.timeOfDayTags.contains(section) || candidate.timeOfDayTags.contains(.anytime) else {
            return (0, nil)
        }

        return (Weights.timeOfDayFit, sectionReason(for: section))
    }

    static func preferenceScore(
        candidate: PlanningCandidate,
        preferences: Set<String>
    ) -> (score: Int, reason: PlanningReason?) {
        guard let category = candidate.category else { return (0, nil) }

        let score: Int
        switch category {
        case .cafes:
            score = preferences.contains("cafes") ? Weights.preferenceMatch : 0
        case .food:
            score = (preferences.contains("foodfocused") || preferences.contains("food-focused")) ? Weights.preferenceMatch : 0
        case .sights:
            score = preferences.contains("sightseeing") ? Weights.preferenceMatch : 0
        case .nightlife:
            score = (preferences.contains("nightout") || preferences.contains("night out")) ? Weights.preferenceMatch : 0
        case .shopping:
            score = preferences.contains("relaxed") ? 1 : 0
        }

        return score > 0 ? (score, .matchesPreferences) : (0, nil)
    }

    static func mappedScore(
        candidate: PlanningCandidate,
        isRouteAware: Bool
    ) -> (score: Int, reason: PlanningReason?) {
        if candidate.isMapped {
            return (Weights.mappedPlace, .mappedPlace)
        }

        return isRouteAware ? (Weights.fallbackRoutePenalty, .fallbackSuggestion) : (0, .fallbackSuggestion)
    }

    static func statusPenalty(
        candidate: PlanningCandidate,
        context: PlanningContext
    ) -> (score: Int, reason: PlanningReason?) {
        if context.normalizedVisitedPlaceNames.contains(candidate.normalizedName) {
            return (Weights.visitedPenalty, .alreadyVisited)
        }

        if context.normalizedSkippedActivityNames.contains(candidate.normalizedName) {
            return (Weights.skippedPenalty, .previouslySkipped)
        }

        return (0, nil)
    }

    static func proximityBonus(distance: Double?) -> (score: Int, reason: PlanningReason?) {
        guard let distance, distance < 0.0025 else { return (0, nil) }
        return (Weights.nearbyStop, .nearAnotherStop)
    }

    static func repeatedCategoryPenalty(
        candidate: PlanningCandidate,
        selectedCandidates: [PlanningCandidate]
    ) -> (score: Int, reason: PlanningReason?) {
        guard let category = candidate.category else { return (0, nil) }
        let repeatedCount = selectedCandidates.filter { $0.category == category }.count
        guard repeatedCount >= 2 else { return (0, nil) }
        return (Weights.repeatedCategoryPenalty, .repeatedCategory)
    }

    static func preserveCurrentPlanBonus(
        candidate: PlanningCandidate,
        preserveExistingBias: Bool
    ) -> (score: Int, reason: PlanningReason?) {
        guard preserveExistingBias, candidate.source == SavedPlace.Source.itinerary.rawValue else {
            return (0, nil)
        }

        return (Weights.preserveCurrentPlan, .preservesCurrentPlan)
    }

    static func shouldPreferReplacement(
        currentScore: CandidateScore,
        replacementScore: CandidateScore
    ) -> Bool {
        let currentIsWeak = currentScore.total <= Weights.lowQualityThreshold
        let replacementClearlyBetter = replacementScore.total >= currentScore.total + Weights.weakReplacementThreshold
        return currentIsWeak && replacementClearlyBetter
    }

    static func preferredSectionOrder(for context: PlanningContext) -> [TimeOfDayTag] {
        if context.normalizedPreferences.contains("nightout") || context.normalizedPreferences.contains("night out") {
            return [.morning, .afternoon, .evening]
        }

        return [.morning, .evening, .afternoon]
    }
}
