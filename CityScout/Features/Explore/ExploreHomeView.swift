import SwiftUI

struct ExploreHomeView: View {
    let destinationName: String

    @State private var selectedCategory: POICategory? = nil

    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 12)
    ]

    private var destinationPOIs: [PointOfInterest] {
        Self.allPOIs.filter { $0.city == destinationName }
    }

    private var filteredPOIs: [PointOfInterest] {
        guard let selectedCategory else { return destinationPOIs }
        return destinationPOIs.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                CityHeaderView(destinationName: destinationName)
                    .padding(.horizontal)
                    .padding(.top, 8)

                if destinationPOIs.isEmpty {
                    ContentUnavailableView(
                        "No Points of Interest",
                        systemImage: "map",
                        description: Text("No points of interest are available for \(destinationName) yet.")
                    )
                    .padding(.horizontal)
                    .accessibilityLabel("No points of interest for \(destinationName)")
                    .accessibilityHint("Explore another city or check back later.")
                } else {
                    categoryFilterBar

                    if filteredPOIs.isEmpty {
                        ContentUnavailableView(
                            "No Matches",
                            systemImage: selectedCategory?.icon ?? "line.3.horizontal.decrease.circle",
                            description: Text("No \(selectedCategory?.displayName.lowercased() ?? "points of interest") are available in \(destinationName) right now.")
                        )
                        .padding(.horizontal)
                        .accessibilityLabel("No \(selectedCategory?.displayName ?? "matching") places in \(destinationName)")
                        .accessibilityHint("Choose another category to see more places.")
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
                                .accessibilityLabel("\(poi.name). Category: \(poi.category.displayName). \(poi.shortDescription)")
                                .accessibilityHint("Opens details and save option.")
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.bottom)
        }
        .navigationTitle("\(destinationName) Explore")
        .animation(.easeInOut(duration: 0.2), value: selectedCategory)
    }

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                categoryChip(
                    title: "All",
                    icon: "square.grid.2x2.fill",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }
                .accessibilityLabel("Show all categories")
                .accessibilityHint("Shows all locations.")
                .accessibilityValue(selectedCategory == nil ? "Selected" : "Not selected")

                ForEach(POICategory.allCases) { category in
                    categoryChip(
                        title: category.displayName,
                        icon: category.icon,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = selectedCategory == category ? nil : category
                    }
                    .accessibilityLabel("Filter by \(category.displayName)")
                    .accessibilityHint("Shows only \(category.displayName.lowercased()) locations.")
                    .accessibilityAddTraits(selectedCategory == category ? .isSelected : [])
                }
            }
            .padding(.horizontal)
        }
    }

    private func categoryChip(
        title: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                )
                .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
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
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(poi.shortDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Label(poi.category.displayName, systemImage: poi.category.icon)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityElement(children: .combine)
    }
}

private extension ExploreHomeView {
    static let allPOIs: [PointOfInterest] = [
        PointOfInterest(
            city: "Paris",
            category: .sights,
            name: "Eiffel Tower",
            shortDescription: "Iconic wrought-iron landmark with panoramic city views.",
            symbolName: "tower",
            latitude: 48.8584,
            longitude: 2.2945
        ),
        PointOfInterest(
            city: "Paris",
            category: .sights,
            name: "Louvre Museum",
            shortDescription: "World-class art museum and home of the Mona Lisa.",
            symbolName: "building.columns",
            latitude: 48.8606,
            longitude: 2.3376
        ),
        PointOfInterest(
            city: "Paris",
            category: .cafes,
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
            name: "Galeries Lafayette",
            shortDescription: "Historic department store with fashion, food halls, and a rooftop view.",
            symbolName: "bag",
            latitude: 48.8720,
            longitude: 2.3320
        ),
        PointOfInterest(
            city: "Barcelona",
            category: .sights,
            name: "Sagrada Familia",
            shortDescription: "Gaudi's basilica and one of Barcelona's top landmarks.",
            symbolName: "building.columns.fill",
            latitude: 41.4036,
            longitude: 2.1744
        ),
        PointOfInterest(
            city: "Barcelona",
            category: .sights,
            name: "Park Guell",
            shortDescription: "Whimsical park with mosaic art and city viewpoints.",
            symbolName: "leaf",
            latitude: 41.4145,
            longitude: 2.1527
        ),
        PointOfInterest(
            city: "Barcelona",
            category: .nightlife,
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
            name: "La Boqueria Market",
            shortDescription: "Busy food market with produce, tapas counters, and local specialties.",
            symbolName: "fork.knife",
            latitude: 41.3822,
            longitude: 2.1717
        )
    ]
}

#Preview {
    NavigationStack {
        ExploreHomeView(destinationName: "Paris")
    }
}
