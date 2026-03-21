import Foundation
import SwiftData

@Model
final class SavedPlace {
    var id: UUID
    var name: String
    var category: POICategory?
    var destinationName: String
    var latitude: Double
    var longitude: Double
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        category: POICategory? = nil,
        destinationName: String = "",
        latitude: Double,
        longitude: Double,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.destinationName = destinationName
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
    }
}
