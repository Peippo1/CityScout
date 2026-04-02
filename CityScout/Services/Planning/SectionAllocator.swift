import Foundation

struct SectionAllocator {
    private let scorer: PlannerScorer

    init(scorer: PlannerScorer) {
        self.scorer = scorer
    }

    func allocate(
        candidates: [PlanningCandidate],
        context: PlanningContext,
        skeleton: PlanSkeleton,
        preserveExistingBias: Bool = false
    ) -> (morning: [PlanningCandidate], afternoon: [PlanningCandidate], evening: [PlanningCandidate]) {
        var remainingCandidates = candidates
        var allocatedSections: [TimeOfDayTag: [PlanningCandidate]] = [
            .morning: [],
            .afternoon: [],
            .evening: []
        ]

        for section in PlanningRules.preferredSectionOrder(for: context) {
            let limit = limit(for: section, skeleton: skeleton)
            guard limit > 0 else { continue }

            while allocatedSections[section, default: []].count < limit, remainingCandidates.isEmpty == false {
                guard let bestMatch = bestCandidateIndex(
                    in: remainingCandidates,
                    for: section,
                    selectedCandidates: allocatedSections[section, default: []],
                    context: context,
                    preserveExistingBias: preserveExistingBias
                ) else {
                    break
                }

                let selectedCandidate = remainingCandidates.remove(at: bestMatch)
                let selectedScore = scorer.score(
                    candidate: selectedCandidate,
                    for: section,
                    selectedCandidates: allocatedSections[section, default: []],
                    context: context,
                    preserveExistingBias: preserveExistingBias
                )

                if selectedScore.total <= PlanningRules.Weights.lowQualityThreshold &&
                    allocatedSections[section, default: []].isEmpty == false {
                    break
                }

                allocatedSections[section, default: []].append(selectedCandidate)
            }
        }

        return (
            morning: LocalRouteOptimizer.optimize(allocatedSections[.morning, default: []]),
            afternoon: LocalRouteOptimizer.optimize(allocatedSections[.afternoon, default: []]),
            evening: LocalRouteOptimizer.optimize(allocatedSections[.evening, default: []])
        )
    }

    private func limit(for section: TimeOfDayTag, skeleton: PlanSkeleton) -> Int {
        switch section {
        case .morning:
            return skeleton.morningCount
        case .afternoon:
            return skeleton.afternoonCount
        case .evening:
            return skeleton.eveningCount
        case .anytime:
            return 0
        }
    }

    private func bestCandidateIndex(
        in candidates: [PlanningCandidate],
        for section: TimeOfDayTag,
        selectedCandidates: [PlanningCandidate],
        context: PlanningContext,
        preserveExistingBias: Bool
    ) -> Int? {
        candidates.enumerated().max { lhs, rhs in
            let lhsScore = scorer.score(
                candidate: lhs.element,
                for: section,
                selectedCandidates: selectedCandidates,
                context: context,
                preserveExistingBias: preserveExistingBias
            )
            let rhsScore = scorer.score(
                candidate: rhs.element,
                for: section,
                selectedCandidates: selectedCandidates,
                context: context,
                preserveExistingBias: preserveExistingBias
            )
            return lhsScore.total < rhsScore.total
        }?.offset
    }
}
