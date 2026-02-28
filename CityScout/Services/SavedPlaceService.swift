import Foundation
import SwiftData

enum SavedPlaceService {
    static func savePlace(
        name: String,
        latitude: Double,
        longitude: Double,
        in modelContext: ModelContext
    ) throws {
        let place = SavedPlace(
            name: name,
            latitude: latitude,
            longitude: longitude
        )
        modelContext.insert(place)
        try modelContext.save()
    }
}
