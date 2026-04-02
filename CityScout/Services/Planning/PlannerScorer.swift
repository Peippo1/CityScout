import Foundation

struct PlannerScorer {
    func score(
        candidate: PlanningCandidate,
        for section: TimeOfDayTag,
        selectedCandidates: [PlanningCandidate],
        context: PlanningContext,
        preserveExistingBias: Bool = false
    ) -> CandidateScore {
        var total = 0
        var reasons: [PlanningReason] = []

        let timeScore = PlanningRules.timeOfDayScore(candidate: candidate, section: section)
        total += timeScore.score
        if let reason = timeScore.reason { reasons.append(reason) }

        let mappedScore = PlanningRules.mappedScore(candidate: candidate, isRouteAware: selectedCandidates.isEmpty == false)
        total += mappedScore.score
        if let reason = mappedScore.reason { reasons.append(reason) }

        let preferenceScore = PlanningRules.preferenceScore(candidate: candidate, preferences: context.normalizedPreferences)
        total += preferenceScore.score
        if let reason = preferenceScore.reason { reasons.append(reason) }

        let statusPenalty = PlanningRules.statusPenalty(candidate: candidate, context: context)
        total += statusPenalty.score
        if let reason = statusPenalty.reason { reasons.append(reason) }

        let proximityBonus = PlanningRules.proximityBonus(distance: nearestDistance(from: candidate, to: selectedCandidates))
        total += proximityBonus.score
        if let reason = proximityBonus.reason { reasons.append(reason) }

        let repeatPenalty = PlanningRules.repeatedCategoryPenalty(candidate: candidate, selectedCandidates: selectedCandidates)
        total += repeatPenalty.score
        if let reason = repeatPenalty.reason { reasons.append(reason) }

        let preserveBonus = PlanningRules.preserveCurrentPlanBonus(candidate: candidate, preserveExistingBias: preserveExistingBias)
        total += preserveBonus.score
        if let reason = preserveBonus.reason { reasons.append(reason) }

        return CandidateScore(candidateID: candidate.id, total: total, reasons: reasons)
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
