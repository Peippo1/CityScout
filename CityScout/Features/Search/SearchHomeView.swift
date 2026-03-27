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
        PointOfInterest.pois(in: destinationName)
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

#Preview {
    NavigationStack {
        SearchHomeView(destinationName: "Paris")
    }
}
