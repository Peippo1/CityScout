import Foundation

enum POICategory: String, CaseIterable, Identifiable, Hashable {
    case food
    case sights
    case cafes
    case shopping
    case nightlife

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .food:
            return "Food"
        case .sights:
            return "Sights"
        case .cafes:
            return "Cafés"
        case .shopping:
            return "Shopping"
        case .nightlife:
            return "Nightlife"
        }
    }

    var icon: String {
        switch self {
        case .food:
            return "fork.knife"
        case .sights:
            return "camera.fill"
        case .cafes:
            return "cup.and.saucer.fill"
        case .shopping:
            return "bag.fill"
        case .nightlife:
            return "moon.stars.fill"
        }
    }
}

struct PointOfInterest: Identifiable, Hashable {
    let id: UUID
    let city: String
    let category: POICategory
    let name: String
    let shortDescription: String
    let symbolName: String
    let latitude: Double
    let longitude: Double

    init(
        id: UUID = UUID(),
        city: String,
        category: POICategory,
        name: String,
        shortDescription: String,
        symbolName: String,
        latitude: Double,
        longitude: Double
    ) {
        self.id = id
        self.city = city
        self.category = category
        self.name = name
        self.shortDescription = shortDescription
        self.symbolName = symbolName
        self.latitude = latitude
        self.longitude = longitude
    }
}
