import SwiftUI
import SwiftData
import MapKit

private enum SearchScopeFilter: String, CaseIterable, Identifiable {
    case all
    case places
    case saved

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .places:
            return "Places"
        case .saved:
            return "Saved"
        }
    }
}

struct SearchHomeView: View {
    let destinationName: String

    @Query private var savedPlaces: [SavedPlace]

    @State private var searchText = ""
    @State private var selectedScope: SearchScopeFilter = .all
    @State private var selectedSavedPlace: SavedPlace?

    init(destinationName: String) {
        self.destinationName = destinationName
        _savedPlaces = Query(
            filter: #Predicate { place in
                place.destinationName == destinationName
            },
            sort: [SortDescriptor(\SavedPlace.createdAt, order: .reverse)]
        )
    }

    private var destinationPOIs: [PointOfInterest] {
        Self.allPOIs.filter { $0.city == destinationName }
    }

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredPOIs: [PointOfInterest] {
        guard normalizedSearchText.isEmpty == false else { return [] }

        return destinationPOIs.filter { poi in
            poi.name.localizedCaseInsensitiveContains(normalizedSearchText)
                || poi.shortDescription.localizedCaseInsensitiveContains(normalizedSearchText)
                || poi.category.displayName.localizedCaseInsensitiveContains(normalizedSearchText)
        }
    }

    private var filteredSavedPlaces: [SavedPlace] {
        guard normalizedSearchText.isEmpty == false else { return [] }

        return savedPlaces.filter { place in
            place.name.localizedCaseInsensitiveContains(normalizedSearchText)
                || (place.category?.displayName.localizedCaseInsensitiveContains(normalizedSearchText) ?? false)
        }
    }

    private var shouldShowPOIs: Bool {
        selectedScope == .all || selectedScope == .places
    }

    private var shouldShowSavedPlaces: Bool {
        selectedScope == .all || selectedScope == .saved
    }

    private var hasResults: Bool {
        (shouldShowPOIs && filteredPOIs.isEmpty == false)
            || (shouldShowSavedPlaces && filteredSavedPlaces.isEmpty == false)
    }

    var body: some View {
        Group {
            if normalizedSearchText.isEmpty {
                promptView
            } else if hasResults == false {
                ContentUnavailableView.search(text: normalizedSearchText)
            } else {
                List {
                    if shouldShowPOIs, filteredPOIs.isEmpty == false {
                        Section("Points of Interest") {
                            ForEach(filteredPOIs) { poi in
                                NavigationLink {
                                    POIDetailView(poi: poi, destinationName: destinationName)
                                } label: {
                                    SearchResultRow(
                                        icon: poi.symbolName,
                                        title: poi.name,
                                        subtitle: poi.category.displayName
                                    )
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("\(poi.name), \(poi.category.displayName), \(destinationName)")
                                .accessibilityHint("Opens point of interest details.")
                            }
                        }
                    }

                    if shouldShowSavedPlaces, filteredSavedPlaces.isEmpty == false {
                        Section("Saved Places") {
                            ForEach(filteredSavedPlaces) { place in
                                Button {
                                    selectedSavedPlace = place
                                } label: {
                                    SearchResultRow(
                                        icon: place.category?.icon ?? "mappin.circle.fill",
                                        title: place.name,
                                        subtitle: place.category?.displayName ?? "Saved place"
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("\(place.name), \(place.category?.displayName ?? "Saved place"), \(destinationName)")
                                .accessibilityHint("Shows saved place details.")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("\(destinationName) Search")
        .searchable(text: $searchText, prompt: "Search places and saved spots")
        .sheet(item: $selectedSavedPlace) { place in
            SavedPlaceSearchDetailView(place: place)
        }
        .safeAreaInset(edge: .top) {
            VStack(alignment: .leading, spacing: 16) {
                CityHeaderView(destinationName: destinationName)
                    .padding(.horizontal)
                    .padding(.top, 8)

                Picker("Search filter", selection: $selectedScope) {
                    ForEach(SearchScopeFilter.allCases) { scope in
                        Text(scope.title).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .accessibilityLabel("Search filter")
                .accessibilityHint("Filters search results by points of interest or saved places.")
            }
            .background(.regularMaterial)
        }
    }

    private var promptView: some View {
        ContentUnavailableView(
            "Search",
            systemImage: "magnifyingglass",
            description: Text("Search for places, cafés, sights, and saved spots in \(destinationName)")
        )
        .accessibilityLabel("Search for places, cafés, sights, and saved spots in \(destinationName)")
    }
}

private struct SearchResultRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color.accentColor)
                .frame(width: 18)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.leading)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SavedPlaceSearchDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let place: SavedPlace

    var body: some View {
        NavigationStack {
            List {
                Section("Place") {
                    Text(place.name)
                        .font(.title3)
                }

                Section("Context") {
                    Text(place.destinationName)
                    Text(place.category?.displayName ?? "Saved place")
                }

                Section("Coordinates") {
                    Text("\(place.latitude.formatted(.number.precision(.fractionLength(4)))), \(place.longitude.formatted(.number.precision(.fractionLength(4))))")
                }

                Section("Saved") {
                    Text(place.createdAt, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                }

                Section {
                    Button("Open in Maps") {
                        openInMaps()
                    }
                    .accessibilityLabel("Open \(place.name) in Maps")
                    .accessibilityHint("Opens Apple Maps for this saved place.")
                }
            }
            .navigationTitle(place.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .accessibilityLabel("Close saved place details")
                }
            }
        }
    }

    private func openInMaps() {
        // TODO: update deprecated MKPlacemark API for newer iOS SDK
        let placemark = MKPlacemark(
            coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
        )
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = place.name
        mapItem.openInMaps()
    }
}

private extension SearchHomeView {
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

#Preview {
    NavigationStack {
        SearchHomeView(destinationName: "Paris")
    }
}
