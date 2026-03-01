import Foundation
import SwiftData

enum SavedPlaceService {
    static func savePlace(
        name: String,
        destinationName: String,
        latitude: Double,
        longitude: Double,
        in modelContext: ModelContext
    ) throws {
        let place = SavedPlace(
            name: name,
            destinationName: destinationName,
            latitude: latitude,
            longitude: longitude
        )
        modelContext.insert(place)
        try modelContext.save()
    }
}
