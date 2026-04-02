import Foundation

struct PlannerExplainer {
    func explanations(for reasons: [PlanningReason], source: PlannedActivitySource) -> [String] {
        let sourceExplanation: String

        switch source {
        case .aiGenerated:
            sourceExplanation = "Generated with AI and checked locally."
        case .builtFromSaved:
            sourceExplanation = "Built from your saved places."
        case .optimizedExisting:
            sourceExplanation = "Refined locally from your current plan."
        }

        let detailExplanations = reasons.map(explanation(for:))
        return [sourceExplanation] + detailExplanations
    }

    func microcopy(for activity: PlannedActivity) -> String {
        if let firstDetail = activity.explanations.dropFirst().first {
            return firstDetail
        }

        switch activity.source {
        case .aiGenerated:
            return "Checked locally"
        case .builtFromSaved:
            return "Built from saved places"
        case .optimizedExisting:
            return "Optimized locally"
        }
    }

    private func explanation(for reason: PlanningReason) -> String {
        switch reason {
        case .goodMorningFit:
            return "Good fit for morning."
        case .goodAfternoonFit:
            return "Good fit for afternoon."
        case .goodEveningFit:
            return "Good fit for evening."
        case .matchesPreferences:
            return "Matches your selected preferences."
        case .mappedPlace:
            return "Known mapped place."
        case .nearAnotherStop:
            return "Near another selected stop."
        case .alreadyVisited:
            return "Already visited."
        case .previouslySkipped:
            return "Previously skipped."
        case .fallbackSuggestion:
            return "Fallback suggestion with limited map detail."
        case .preservesCurrentPlan:
            return "Preserves the tone of your current plan."
        case .improvesWeakStop:
            return "Stronger local replacement for a weaker stop."
        case .balancesTheDay:
            return "Helps balance the day."
        case .keepsEveningSpace:
            return "Keeps space for dinner or evening plans."
        case .repeatedCategory:
            return "Repeated category, so it was deprioritized."
        }
    }
}
