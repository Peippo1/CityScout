import Foundation
import SwiftData

enum SavedPlaceService {
    static func savePlace(
        name: String,
        category: POICategory? = nil,
        destinationName: String,
        latitude: Double,
        longitude: Double,
        in modelContext: ModelContext
    ) throws {
        let place = SavedPlace(
            name: name,
            category: category,
            destinationName: destinationName,
            latitude: latitude,
            longitude: longitude
        )
        modelContext.insert(place)
        try modelContext.save()
    }

    static func deletePlace(_ place: SavedPlace, in modelContext: ModelContext) throws {
        modelContext.delete(place)
        try modelContext.save()
    }
}
