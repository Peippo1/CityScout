import Foundation
import SwiftData

@Model
final class SavedPlace {
    enum Source: String {
        case manual
        case poi
        case itinerary
    }

    var id: UUID
    var name: String
    var categoryRaw: String?
    var source: String?
    var destinationName: String
    var latitude: Double
    var longitude: Double
    var createdAt: Date

    var category: POICategory? {
        get {
            guard let categoryRaw else { return nil }
            return POICategory(rawValue: categoryRaw)
        }
        set {
            categoryRaw = newValue?.rawValue
        }
    }

    var isItineraryDerived: Bool {
        source == Source.itinerary.rawValue
    }

    init(
        id: UUID = UUID(),
        name: String,
        category: POICategory? = nil,
        source: String? = nil,
        destinationName: String = "",
        latitude: Double,
        longitude: Double,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.categoryRaw = category?.rawValue
        self.source = source
        self.destinationName = destinationName
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
    }
}
