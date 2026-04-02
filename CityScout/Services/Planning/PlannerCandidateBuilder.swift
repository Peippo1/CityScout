import Foundation

struct PlannerCandidateBuilder {
    func savedPlaceCandidates(from context: PlanningContext) -> [PlanningCandidate] {
        var seenNames: Set<String> = []
        var candidates: [PlanningCandidate] = []

        for place in context.savedPlaces
            .filter({ $0.destinationName == context.destinationName })
            .sorted(by: { $0.createdAt > $1.createdAt }) {
            let normalizedName = SavedPlaceService.normalizedPlaceName(place.name)
            guard normalizedName.isEmpty == false else { continue }
            guard context.normalizedVisitedPlaceNames.contains(normalizedName) == false else { continue }
            guard context.normalizedSkippedActivityNames.contains(normalizedName) == false else { continue }
            guard seenNames.insert(normalizedName).inserted else { continue }

            candidates.append(
                candidate(
                    name: place.name,
                    mappedPlaceName: place.name,
                    category: place.category,
                    destinationName: place.destinationName,
                    latitude: place.latitude,
                    longitude: place.longitude,
                    source: place.source ?? SavedPlace.Source.manual.rawValue
                )
            )
        }

        return candidates
    }

    func itineraryCandidates(
        from itinerary: PlanAPIService.ItineraryResponse,
        context: PlanningContext,
        resolveSavedPlace: (String) -> ResolvedItineraryPlace
    ) -> [PlanningCandidate] {
        let orderedActivities = PlanSavedPlaceSupport.orderedUniqueActivityNames(
            from: itinerary.morning.activities + itinerary.afternoon.activities + itinerary.evening.activities
        )

        return orderedActivities.compactMap { activity in
            let normalizedName = SavedPlaceService.normalizedPlaceName(activity)
            guard normalizedName.isEmpty == false else { return nil }
            guard context.normalizedSkippedActivityNames.contains(normalizedName) == false else { return nil }

            let resolvedPlace = resolveSavedPlace(activity)
            let mappedName = resolvedPlace.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let finalMappedName = mappedName.isEmpty ? nil : mappedName

            return candidate(
                name: activity,
                mappedPlaceName: finalMappedName,
                category: resolvedPlace.category,
                destinationName: context.destinationName,
                latitude: resolvedPlace.latitude,
                longitude: resolvedPlace.longitude,
                source: SavedPlace.Source.itinerary.rawValue
            )
        }
    }

    func candidate(
        name: String,
        mappedPlaceName: String?,
        category: POICategory?,
        destinationName: String,
        latitude: Double,
        longitude: Double,
        source: String
    ) -> PlanningCandidate {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedName = SavedPlaceService.normalizedPlaceName(trimmedName)

        return PlanningCandidate(
            id: normalizedName,
            name: trimmedName,
            normalizedName: normalizedName,
            mappedPlaceName: {
                let trimmedMappedName = mappedPlaceName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return trimmedMappedName.isEmpty ? nil : trimmedMappedName
            }(),
            category: category,
            destinationName: destinationName,
            latitude: latitude,
            longitude: longitude,
            source: source,
            timeOfDayTags: timeOfDayTags(for: category),
            experienceTags: experienceTags(for: category),
            isMapped: latitude != 0 || longitude != 0
        )
    }

    private func timeOfDayTags(for category: POICategory?) -> Set<TimeOfDayTag> {
        switch category {
        case .cafes:
            return [.morning, .afternoon]
        case .food:
            return [.afternoon, .evening]
        case .sights:
            return [.morning, .afternoon]
        case .shopping:
            return [.afternoon, .evening]
        case .nightlife:
            return [.evening]
        case nil:
            return [.anytime]
        }
    }

    private func experienceTags(for category: POICategory?) -> Set<ExperienceTag> {
        switch category {
        case .cafes:
            return [.foodDrink, .relax]
        case .food:
            return [.foodDrink, .indoor]
        case .sights:
            return [.culture, .landmark, .outdoor]
        case .shopping:
            return [.shopping, .indoor]
        case .nightlife:
            return [.nightlife, .foodDrink]
        case nil:
            return [.relax]
        }
    }
}
