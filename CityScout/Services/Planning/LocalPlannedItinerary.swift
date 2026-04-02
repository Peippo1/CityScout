import Foundation

enum ItemConfidence: String, Hashable {
    case high
    case medium
    case low
}

enum MappingStatus: String, Hashable {
    case matchedPOI
    case fallback
}

enum PlannedActivitySource: String, Hashable {
    case aiGenerated
    case builtFromSaved
    case optimizedExisting
}

struct PlannedActivity: Identifiable, Hashable {
    let id: String
    let title: String
    let mappedPlaceName: String?
    let mappingStatus: MappingStatus
    let confidence: ItemConfidence
    let latitude: Double?
    let longitude: Double?
    let source: PlannedActivitySource
}

struct PlannedSection: Identifiable, Hashable {
    let title: String
    let items: [PlannedActivity]

    var id: String { title }
}

struct LocalPlannedItinerary: Hashable {
    let destination: String
    let morning: PlannedSection
    let afternoon: PlannedSection
    let evening: PlannedSection
    let notes: [String]
    let narrative: String?

    var sections: [PlannedSection] {
        [morning, afternoon, evening]
    }

    var asServiceResponse: PlanAPIService.ItineraryResponse {
        PlanAPIService.ItineraryResponse(
            destination: destination,
            morning: .init(title: morning.title, activities: morning.items.map(\.title)),
            afternoon: .init(title: afternoon.title, activities: afternoon.items.map(\.title)),
            evening: .init(title: evening.title, activities: evening.items.map(\.title)),
            notes: notes
        )
    }

    func activity(named title: String, inSection sectionTitle: String) -> PlannedActivity? {
        sections
            .first(where: { $0.title == sectionTitle })?
            .items
            .first(where: { $0.title == title })
    }
}
