import Foundation

struct PointOfInterest: Identifiable, Hashable {
    let id: UUID
    let city: String
    let name: String
    let shortDescription: String
    let symbolName: String
    let latitude: Double
    let longitude: Double

    init(
        id: UUID = UUID(),
        city: String,
        name: String,
        shortDescription: String,
        symbolName: String,
        latitude: Double,
        longitude: Double
    ) {
        self.id = id
        self.city = city
        self.name = name
        self.shortDescription = shortDescription
        self.symbolName = symbolName
        self.latitude = latitude
        self.longitude = longitude
    }
}
