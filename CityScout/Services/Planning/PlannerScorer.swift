import Foundation

struct PlannerScorer {
    func score(
        candidate: PlanningCandidate,
        for section: TimeOfDayTag,
        selectedCandidates: [PlanningCandidate],
        context: PlanningContext
    ) -> CandidateScore {
        var total = 0
        var reasons: [String] = []

        if candidate.timeOfDayTags.contains(section) || candidate.timeOfDayTags.contains(.anytime) {
            total += 2
            reasons.append("Good \(section.rawValue) fit")
        }

        if candidate.isMapped {
            total += 2
            reasons.append("Mapped place")
        } else if selectedCandidates.isEmpty == false {
            total -= 1
            reasons.append("No coordinates")
        }

        if let category = candidate.category, preferenceBonus(for: category, preferences: context.normalizedPreferences) > 0 {
            let bonus = preferenceBonus(for: category, preferences: context.normalizedPreferences)
            total += bonus
            reasons.append("Matches preferences")
        }

        if context.normalizedVisitedPlaceNames.contains(candidate.normalizedName) {
            total -= 5
            reasons.append("Already visited")
        }

        if context.normalizedSkippedActivityNames.contains(candidate.normalizedName) {
            total -= 4
            reasons.append("Previously skipped")
        }

        if let nearestDistance = nearestDistance(from: candidate, to: selectedCandidates), nearestDistance < 0.0025 {
            total += 2
            reasons.append("Near another stop")
        }

        return CandidateScore(candidateID: candidate.id, total: total, reasons: reasons)
    }

    private func preferenceBonus(for category: POICategory, preferences: Set<String>) -> Int {
        switch category {
        case .cafes:
            return preferences.contains("cafes") ? 3 : 0
        case .food:
            return preferences.contains("foodfocused") || preferences.contains("food-focused") ? 3 : 0
        case .sights:
            return preferences.contains("sightseeing") ? 3 : 0
        case .nightlife:
            return preferences.contains("nightout") || preferences.contains("night out") ? 3 : 0
        case .shopping:
            return preferences.contains("relaxed") ? 1 : 0
        }
    }

    private func nearestDistance(from candidate: PlanningCandidate, to selectedCandidates: [PlanningCandidate]) -> Double? {
        guard candidate.hasCoordinates else { return nil }

        return selectedCandidates
            .filter(\.hasCoordinates)
            .map { selectedCandidate in
                let latitudeDelta = selectedCandidate.latitude - candidate.latitude
                let longitudeDelta = selectedCandidate.longitude - candidate.longitude
                return (latitudeDelta * latitudeDelta) + (longitudeDelta * longitudeDelta)
            }
            .min()
    }
}
