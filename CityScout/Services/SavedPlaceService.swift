import Foundation
import SwiftData

enum SavedPlaceService {
    static func normalizedPlaceName(_ name: String) -> String {
        name
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.isEmpty == false }
            .joined(separator: " ")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    static func isPlaceSaved(
        name: String,
        destinationName: String,
        in savedPlaces: [SavedPlace]
    ) -> Bool {
        let normalizedName = normalizedPlaceName(name)
        guard normalizedName.isEmpty == false else { return false }

        return savedPlaces.contains { place in
            place.destinationName == destinationName
            && normalizedPlaceName(place.name) == normalizedName
        }
    }

    @discardableResult
    static func savePlaceIfNeeded(
        name: String,
        category: POICategory? = nil,
        source: String? = nil,
        destinationName: String,
        latitude: Double,
        longitude: Double,
        in modelContext: ModelContext
    ) throws -> SavedPlace? {
        let existingPlaces = try modelContext.fetch(
            FetchDescriptor<SavedPlace>(
                predicate: #Predicate<SavedPlace> { place in
                    place.destinationName == destinationName
                }
            )
        )

        guard isPlaceSaved(name: name, destinationName: destinationName, in: existingPlaces) == false else {
            return nil
        }

        let place = SavedPlace(
            name: name,
            category: category,
            source: source,
            destinationName: destinationName,
            latitude: latitude,
            longitude: longitude
        )
        modelContext.insert(place)
        try modelContext.save()
        return place
    }

    static func savePlace(
        name: String,
        category: POICategory? = nil,
        source: String? = nil,
        destinationName: String,
        latitude: Double,
        longitude: Double,
        in modelContext: ModelContext
    ) throws {
        _ = try savePlaceIfNeeded(
            name: name,
            category: category,
            source: source,
            destinationName: destinationName,
            latitude: latitude,
            longitude: longitude,
            in: modelContext
        )
    }

    static func deletePlace(_ place: SavedPlace, in modelContext: ModelContext) throws {
        modelContext.delete(place)
        try modelContext.save()
    }
}
