import Foundation

struct PlanningCandidate: Identifiable, Hashable {
    let id: String
    let name: String
    let normalizedName: String
    let mappedPlaceName: String?
    let category: POICategory?
    let destinationName: String
    let latitude: Double
    let longitude: Double
    let source: String
    let timeOfDayTags: Set<TimeOfDayTag>
    let experienceTags: Set<ExperienceTag>
    let isMapped: Bool

    var hasCoordinates: Bool {
        latitude != 0 || longitude != 0
    }
}

struct CandidateScore {
    let candidateID: String
    let total: Int
    let reasons: [PlanningReason]
}

struct PlanSkeleton {
    let morningCount: Int
    let afternoonCount: Int
    let eveningCount: Int
}
