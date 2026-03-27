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
    let isTopPick: Bool
    let name: String
    let shortDescription: String
    let symbolName: String
    let latitude: Double
    let longitude: Double

    init(
        id: UUID = UUID(),
        city: String,
        category: POICategory,
        isTopPick: Bool = false,
        name: String,
        shortDescription: String,
        symbolName: String,
        latitude: Double,
        longitude: Double
    ) {
        self.id = id
        self.city = city
        self.category = category
        self.isTopPick = isTopPick
        self.name = name
        self.shortDescription = shortDescription
        self.symbolName = symbolName
        self.latitude = latitude
        self.longitude = longitude
    }
}

extension PointOfInterest {
    static func pois(in destinationName: String) -> [PointOfInterest] {
        allPOIs.filter { $0.city == destinationName }
    }

    static let allPOIs: [PointOfInterest] = [
        PointOfInterest(
            city: "Paris",
            category: .sights,
            isTopPick: true,
            name: "Eiffel Tower",
            shortDescription: "Iconic wrought-iron landmark with panoramic city views.",
            symbolName: "tower",
            latitude: 48.8584,
            longitude: 2.2945
        ),
        PointOfInterest(
            city: "Paris",
            category: .sights,
            isTopPick: true,
            name: "Louvre Museum",
            shortDescription: "World-class art museum and home of the Mona Lisa.",
            symbolName: "building.columns",
            latitude: 48.8606,
            longitude: 2.3376
        ),
        PointOfInterest(
            city: "Paris",
            category: .cafes,
            isTopPick: true,
            name: "Montmartre",
            shortDescription: "Historic hilltop district known for artists and cafes.",
            symbolName: "paintpalette",
            latitude: 48.8867,
            longitude: 2.3431
        ),
        PointOfInterest(
            city: "Paris",
            category: .sights,
            name: "Notre-Dame Cathedral",
            shortDescription: "Gothic cathedral on the Ile de la Cite in central Paris.",
            symbolName: "building",
            latitude: 48.8530,
            longitude: 2.3499
        ),
        PointOfInterest(
            city: "Paris",
            category: .shopping,
            isTopPick: true,
            name: "Galeries Lafayette",
            shortDescription: "Historic department store with fashion, food halls, and a rooftop view.",
            symbolName: "bag",
            latitude: 48.8720,
            longitude: 2.3320
        ),
        PointOfInterest(
            city: "Barcelona",
            category: .sights,
            isTopPick: true,
            name: "Sagrada Familia",
            shortDescription: "Gaudi's basilica and one of Barcelona's top landmarks.",
            symbolName: "building.columns.fill",
            latitude: 41.4036,
            longitude: 2.1744
        ),
        PointOfInterest(
            city: "Barcelona",
            category: .sights,
            isTopPick: true,
            name: "Park Guell",
            shortDescription: "Whimsical park with mosaic art and city viewpoints.",
            symbolName: "leaf",
            latitude: 41.4145,
            longitude: 2.1527
        ),
        PointOfInterest(
            city: "Barcelona",
            category: .nightlife,
            isTopPick: true,
            name: "Gothic Quarter",
            shortDescription: "Medieval streets, plazas, and hidden courtyards.",
            symbolName: "building.2",
            latitude: 41.3839,
            longitude: 2.1763
        ),
        PointOfInterest(
            city: "Barcelona",
            category: .sights,
            name: "Casa Batllo",
            shortDescription: "Modernist masterpiece with a colorful Gaudi facade.",
            symbolName: "house",
            latitude: 41.3917,
            longitude: 2.1649
        ),
        PointOfInterest(
            city: "Barcelona",
            category: .food,
            isTopPick: true,
            name: "La Boqueria Market",
            shortDescription: "Busy food market with produce, tapas counters, and local specialties.",
            symbolName: "fork.knife",
            latitude: 41.3822,
            longitude: 2.1717
        )
    ]
}
