import SwiftUI

struct ExploreHomeView: View {
    let destinationName: String

    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 12)
    ]

    private var filteredPOIs: [PointOfInterest] {
        Self.allPOIs.filter { $0.city == destinationName }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if filteredPOIs.isEmpty {
                    ContentUnavailableView(
                        "No Points of Interest",
                        systemImage: "map",
                        description: Text("No points of interest are available for \(destinationName) yet.")
                    )
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(filteredPOIs) { poi in
                            NavigationLink {
                                POIDetailView(poi: poi, destinationName: destinationName)
                            } label: {
                                POITileView(poi: poi)
                            }
                            .buttonStyle(.plain)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(poi.name). \(poi.shortDescription)")
                            .accessibilityHint("Opens details and save option.")
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Explore")
    }
}

private struct POITileView: View {
    let poi: PointOfInterest

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: poi.symbolName)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)

            Text(poi.name)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Text(poi.shortDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

private extension ExploreHomeView {
    static let allPOIs: [PointOfInterest] = [
        PointOfInterest(
            city: "Paris",
            name: "Eiffel Tower",
            shortDescription: "Iconic wrought-iron landmark with panoramic city views.",
            symbolName: "tower",
            latitude: 48.8584,
            longitude: 2.2945
        ),
        PointOfInterest(
            city: "Paris",
            name: "Louvre Museum",
            shortDescription: "World-class art museum and home of the Mona Lisa.",
            symbolName: "building.columns",
            latitude: 48.8606,
            longitude: 2.3376
        ),
        PointOfInterest(
            city: "Paris",
            name: "Montmartre",
            shortDescription: "Historic hilltop district known for artists and cafes.",
            symbolName: "paintpalette",
            latitude: 48.8867,
            longitude: 2.3431
        ),
        PointOfInterest(
            city: "Paris",
            name: "Notre-Dame Cathedral",
            shortDescription: "Gothic cathedral on the Ile de la Cite in central Paris.",
            symbolName: "building",
            latitude: 48.8530,
            longitude: 2.3499
        ),
        PointOfInterest(
            city: "Barcelona",
            name: "Sagrada Familia",
            shortDescription: "Gaudi's basilica and one of Barcelona's top landmarks.",
            symbolName: "building.columns.fill",
            latitude: 41.4036,
            longitude: 2.1744
        ),
        PointOfInterest(
            city: "Barcelona",
            name: "Park Guell",
            shortDescription: "Whimsical park with mosaic art and city viewpoints.",
            symbolName: "leaf",
            latitude: 41.4145,
            longitude: 2.1527
        ),
        PointOfInterest(
            city: "Barcelona",
            name: "Gothic Quarter",
            shortDescription: "Medieval streets, plazas, and hidden courtyards.",
            symbolName: "building.2",
            latitude: 41.3839,
            longitude: 2.1763
        ),
        PointOfInterest(
            city: "Barcelona",
            name: "Casa Batllo",
            shortDescription: "Modernist masterpiece with a colorful Gaudi facade.",
            symbolName: "house",
            latitude: 41.3917,
            longitude: 2.1649
        )
    ]
}

#Preview {
    NavigationStack {
        ExploreHomeView(destinationName: "Paris")
    }
}
