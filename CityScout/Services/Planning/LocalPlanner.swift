import Foundation

struct LocalPlanner {
    private let candidateBuilder = PlannerCandidateBuilder()
    private let scorer = PlannerScorer()
    private let skeletonBuilder = PlanSkeletonBuilder()
    private let narrativeBuilder = PlanningNarrativeBuilder()

    func buildFromSaved(context: PlanningContext) -> LocalPlannedItinerary? {
        let candidates = candidateBuilder.savedPlaceCandidates(from: context)
        guard candidates.isEmpty == false else { return nil }

        let skeleton = skeletonBuilder.skeleton(for: context, candidateCount: candidates.count)
        let selection = selectCandidates(
            from: candidates,
            context: context,
            morningCount: skeleton.morningCount,
            afternoonCount: skeleton.afternoonCount,
            eveningCount: skeleton.eveningCount
        )

        return makeItinerary(
            context: context,
            destinationName: context.destinationName,
            morningCandidates: selection.morning,
            afternoonCandidates: selection.afternoon,
            eveningCandidates: selection.evening,
            source: .builtFromSaved,
            notes: buildFromSavedNotes(totalCandidateCount: candidates.count, itinerarySelection: selection)
        )
    }

    func optimizeExisting(
        context: PlanningContext,
        resolveSavedPlace: (String) -> ResolvedItineraryPlace
    ) -> LocalPlannedItinerary? {
        guard let existingItinerary = context.existingItinerary else { return nil }

        let existingCandidates = candidateBuilder.itineraryCandidates(
            from: existingItinerary,
            context: context,
            resolveSavedPlace: resolveSavedPlace
        )
        let savedPlaceCandidates = candidateBuilder.savedPlaceCandidates(from: context)

        let combinedCandidates = mergeCandidates(
            primary: existingCandidates,
            secondary: savedPlaceCandidates
        )
        guard combinedCandidates.isEmpty == false else { return nil }

        let selection = selectCandidates(
            from: combinedCandidates,
            context: context,
            morningCount: existingItinerary.morning.activities.count,
            afternoonCount: existingItinerary.afternoon.activities.count,
            eveningCount: existingItinerary.evening.activities.count,
            preserveExistingBias: true
        )

        let changedOrder =
            selection.morning.map(\.name) != existingItinerary.morning.activities ||
            selection.afternoon.map(\.name) != existingItinerary.afternoon.activities ||
            selection.evening.map(\.name) != existingItinerary.evening.activities

        return makeItinerary(
            context: context,
            destinationName: context.destinationName,
            morningTitle: existingItinerary.morning.title,
            afternoonTitle: existingItinerary.afternoon.title,
            eveningTitle: existingItinerary.evening.title,
            morningCandidates: selection.morning,
            afternoonCandidates: selection.afternoon,
            eveningCandidates: selection.evening,
            source: .optimizedExisting,
            notes: optimizedNotes(
                existingNotes: existingItinerary.notes,
                destinationName: context.destinationName,
                changedOrder: changedOrder
            )
        )
    }

    func annotateItinerary(
        _ itinerary: PlanAPIService.ItineraryResponse,
        context: PlanningContext,
        source: PlannedActivitySource,
        resolveSavedPlace: (String) -> ResolvedItineraryPlace
    ) -> LocalPlannedItinerary {
        let morningItems = annotateActivities(
            itinerary.morning.activities,
            section: .morning,
            source: source,
            context: context,
            resolveSavedPlace: resolveSavedPlace
        )
        let afternoonItems = annotateActivities(
            itinerary.afternoon.activities,
            section: .afternoon,
            source: source,
            context: context,
            resolveSavedPlace: resolveSavedPlace
        )
        let eveningItems = annotateActivities(
            itinerary.evening.activities,
            section: .evening,
            source: source,
            context: context,
            resolveSavedPlace: resolveSavedPlace
        )

        let baseItinerary = LocalPlannedItinerary(
            destination: context.destinationName,
            morning: PlannedSection(title: itinerary.morning.title, items: morningItems),
            afternoon: PlannedSection(title: itinerary.afternoon.title, items: afternoonItems),
            evening: PlannedSection(title: itinerary.evening.title, items: eveningItems),
            notes: itinerary.notes,
            narrative: nil
        )

        return LocalPlannedItinerary(
            destination: baseItinerary.destination,
            morning: baseItinerary.morning,
            afternoon: baseItinerary.afternoon,
            evening: baseItinerary.evening,
            notes: baseItinerary.notes,
            narrative: narrativeBuilder.narrative(for: baseItinerary)
        )
    }

    private func selectCandidates(
        from candidates: [PlanningCandidate],
        context: PlanningContext,
        morningCount: Int,
        afternoonCount: Int,
        eveningCount: Int,
        preserveExistingBias: Bool = false
    ) -> (morning: [PlanningCandidate], afternoon: [PlanningCandidate], evening: [PlanningCandidate]) {
        var remainingCandidates = candidates
        let morning = pickCandidates(
            from: &remainingCandidates,
            for: .morning,
            limit: morningCount,
            context: context,
            preserveExistingBias: preserveExistingBias
        )
        let evening = pickCandidates(
            from: &remainingCandidates,
            for: .evening,
            limit: eveningCount,
            context: context,
            preserveExistingBias: preserveExistingBias
        )
        let afternoon = pickCandidates(
            from: &remainingCandidates,
            for: .afternoon,
            limit: afternoonCount,
            context: context,
            preserveExistingBias: preserveExistingBias
        )

        return (morning, afternoon, evening)
    }

    private func pickCandidates(
        from candidates: inout [PlanningCandidate],
        for section: TimeOfDayTag,
        limit: Int,
        context: PlanningContext,
        preserveExistingBias: Bool
    ) -> [PlanningCandidate] {
        guard limit > 0, candidates.isEmpty == false else { return [] }

        var selectedCandidates: [PlanningCandidate] = []

        while selectedCandidates.count < limit, candidates.isEmpty == false {
            let bestMatch = candidates.enumerated().max { lhs, rhs in
                let lhsScore = candidateScore(
                    lhs.element,
                    section: section,
                    selectedCandidates: selectedCandidates,
                    context: context,
                    preserveExistingBias: preserveExistingBias
                )
                let rhsScore = candidateScore(
                    rhs.element,
                    section: section,
                    selectedCandidates: selectedCandidates,
                    context: context,
                    preserveExistingBias: preserveExistingBias
                )
                return lhsScore.total < rhsScore.total
            }

            guard let bestMatch else { break }
            selectedCandidates.append(candidates.remove(at: bestMatch.offset))
        }

        return LocalRouteOptimizer.optimize(selectedCandidates)
    }

    private func candidateScore(
        _ candidate: PlanningCandidate,
        section: TimeOfDayTag,
        selectedCandidates: [PlanningCandidate],
        context: PlanningContext,
        preserveExistingBias: Bool
    ) -> CandidateScore {
        var baseScore = scorer.score(
            candidate: candidate,
            for: section,
            selectedCandidates: selectedCandidates,
            context: context
        )

        if preserveExistingBias, candidate.source == SavedPlace.Source.itinerary.rawValue {
            baseScore = CandidateScore(
                candidateID: baseScore.candidateID,
                total: baseScore.total + 2,
                reasons: baseScore.reasons + ["Preserves current plan"]
            )
        }

        return baseScore
    }

    private func mergeCandidates(
        primary: [PlanningCandidate],
        secondary: [PlanningCandidate]
    ) -> [PlanningCandidate] {
        var seenNames = Set(primary.map(\.normalizedName))
        var mergedCandidates = primary

        for candidate in secondary where seenNames.insert(candidate.normalizedName).inserted {
            mergedCandidates.append(candidate)
        }

        return mergedCandidates
    }

    private func annotateActivities(
        _ activities: [String],
        section: TimeOfDayTag,
        source: PlannedActivitySource,
        context: PlanningContext,
        resolveSavedPlace: (String) -> ResolvedItineraryPlace
    ) -> [PlannedActivity] {
        let candidates = activities.map { activity -> PlanningCandidate in
            let resolvedPlace = resolveSavedPlace(activity)
            return candidateBuilder.candidate(
                name: activity,
                mappedPlaceName: resolvedPlace.name,
                category: resolvedPlace.category,
                destinationName: context.destinationName,
                latitude: resolvedPlace.latitude,
                longitude: resolvedPlace.longitude,
                source: SavedPlace.Source.itinerary.rawValue
            )
        }

        return candidates.map { candidate in
            let score = scorer.score(
                candidate: candidate,
                for: section,
                selectedCandidates: [],
                context: context
            )
            return makePlannedActivity(candidate: candidate, score: score, source: source)
        }
    }

    private func makeItinerary(
        context: PlanningContext,
        destinationName: String,
        morningTitle: String = "Morning",
        afternoonTitle: String = "Afternoon",
        eveningTitle: String = "Evening",
        morningCandidates: [PlanningCandidate],
        afternoonCandidates: [PlanningCandidate],
        eveningCandidates: [PlanningCandidate],
        source: PlannedActivitySource,
        notes: [String]
    ) -> LocalPlannedItinerary {
        let morningItems = morningCandidates.map {
            makePlannedActivity(candidate: $0, score: scorer.score(candidate: $0, for: .morning, selectedCandidates: [], context: context), source: source)
        }
        let afternoonItems = afternoonCandidates.map {
            makePlannedActivity(candidate: $0, score: scorer.score(candidate: $0, for: .afternoon, selectedCandidates: [], context: context), source: source)
        }
        let eveningItems = eveningCandidates.map {
            makePlannedActivity(candidate: $0, score: scorer.score(candidate: $0, for: .evening, selectedCandidates: [], context: context), source: source)
        }

        let baseItinerary = LocalPlannedItinerary(
            destination: destinationName,
            morning: PlannedSection(title: morningTitle, items: morningItems),
            afternoon: PlannedSection(title: afternoonTitle, items: afternoonItems),
            evening: PlannedSection(title: eveningTitle, items: eveningItems),
            notes: notes,
            narrative: nil
        )

        return LocalPlannedItinerary(
            destination: baseItinerary.destination,
            morning: baseItinerary.morning,
            afternoon: baseItinerary.afternoon,
            evening: baseItinerary.evening,
            notes: baseItinerary.notes,
            narrative: narrativeBuilder.narrative(for: baseItinerary)
        )
    }

    private func makePlannedActivity(
        candidate: PlanningCandidate,
        score: CandidateScore,
        source: PlannedActivitySource
    ) -> PlannedActivity {
        let mappingStatus: MappingStatus = candidate.isMapped ? .matchedPOI : .fallback
        let confidence: ItemConfidence

        switch (candidate.isMapped, score.total) {
        case (true, 5...):
            confidence = .high
        case (true, _), (false, 4...):
            confidence = .medium
        default:
            confidence = .low
        }

        return PlannedActivity(
            id: candidate.id,
            title: candidate.name,
            mappedPlaceName: candidate.mappedPlaceName,
            mappingStatus: mappingStatus,
            confidence: confidence,
            latitude: candidate.hasCoordinates ? candidate.latitude : nil,
            longitude: candidate.hasCoordinates ? candidate.longitude : nil,
            source: source
        )
    }

    private func buildFromSavedNotes(
        totalCandidateCount: Int,
        itinerarySelection: (morning: [PlanningCandidate], afternoon: [PlanningCandidate], evening: [PlanningCandidate])
    ) -> [String] {
        var notes = [
            "Built locally from your saved places, so this day works even if the planner backend is unavailable.",
            "Morning prioritises cafés and sights, afternoon leans toward sights and shopping, and evening favours food and nightlife."
        ]

        let representedSections = [
            itinerarySelection.morning.isEmpty == false,
            itinerarySelection.afternoon.isEmpty == false,
            itinerarySelection.evening.isEmpty == false
        ]

        if representedSections.filter({ $0 }).count < 3 {
            notes.append(
                totalCandidateCount == 1
                ? "Save a few more places to fill out the rest of your day."
                : "Save more places to round out the quieter parts of the day."
            )
        }

        return notes
    }

    private func optimizedNotes(
        existingNotes: [String],
        destinationName: String,
        changedOrder: Bool
    ) -> [String] {
        let note = changedOrder
            ? "Optimised locally for a smoother \(destinationName) day by grouping similar stops and keeping nearby places together where possible."
            : "Checked locally and your current day is already balanced for \(destinationName)."

        if existingNotes.contains(note) {
            return existingNotes
        }

        return [note] + existingNotes
    }
}
