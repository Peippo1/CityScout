import Foundation

enum PlanningMode {
    case aiGenerate
    case buildFromSaved
    case optimizeExisting
}

enum TimeOfDayTag: String, CaseIterable, Hashable {
    case morning
    case afternoon
    case evening
    case anytime
}

enum ExperienceTag: String, CaseIterable, Hashable {
    case foodDrink
    case culture
    case landmark
    case relax
    case nightlife
    case indoor
    case outdoor
    case shopping
}

struct PlanningContext {
    let destinationName: String
    let prompt: String
    let preferences: [String]
    let savedPlaces: [SavedPlace]
    let existingItinerary: PlanAPIService.ItineraryResponse?
    let visitedPlaceNames: Set<String>
    let skippedActivityNames: Set<String>
    let timeOfDayBias: TimeOfDayTag?
    let mode: PlanningMode

    init(
        destinationName: String,
        prompt: String = "",
        preferences: [String] = [],
        savedPlaces: [SavedPlace] = [],
        existingItinerary: PlanAPIService.ItineraryResponse? = nil,
        visitedPlaceNames: Set<String> = [],
        skippedActivityNames: Set<String> = [],
        timeOfDayBias: TimeOfDayTag? = nil,
        mode: PlanningMode
    ) {
        self.destinationName = destinationName
        self.prompt = prompt
        self.preferences = preferences
        self.savedPlaces = savedPlaces
        self.existingItinerary = existingItinerary
        self.visitedPlaceNames = visitedPlaceNames
        self.skippedActivityNames = skippedActivityNames
        self.timeOfDayBias = timeOfDayBias
        self.mode = mode
    }

    var normalizedVisitedPlaceNames: Set<String> {
        Set(visitedPlaceNames.map(SavedPlaceService.normalizedPlaceName))
    }

    var normalizedSkippedActivityNames: Set<String> {
        Set(skippedActivityNames.map(SavedPlaceService.normalizedPlaceName))
    }

    var normalizedPreferences: Set<String> {
        Set(
            preferences.map {
                $0.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            }
        )
    }
}
