import SwiftUI

struct SavedPlacesListView: View {
    private enum SavedPlacesFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case itinerary = "Itinerary"
        case other = "Other"

        var id: String { rawValue }
    }

    let destinationName: String
    let savedPlaces: [SavedPlace]
    let onSelectPlace: (SavedPlace) -> Void

    @State private var selectedFilter: SavedPlacesFilter = .all

    private static let categoryOrder: [POICategory?] = [
        .food,
        .cafes,
        .sights,
        .shopping,
        .nightlife,
        nil
    ]

    private var filteredPlaces: [SavedPlace] {
        switch selectedFilter {
        case .all:
            return savedPlaces
        case .itinerary:
            return savedPlaces.filter(\.isItineraryDerived)
        case .other:
            return savedPlaces.filter { $0.isItineraryDerived == false }
        }
    }

    private var groupedPlaces: [POICategory?: [SavedPlace]] {
        Dictionary(grouping: filteredPlaces) { $0.category }
    }

    private var orderedCategories: [POICategory?] {
        Self.categoryOrder.filter { groupedPlaces[$0]?.isEmpty == false }
    }

    var body: some View {
        Group {
            if savedPlaces.isEmpty {
                ContentUnavailableView(
                    "No Saved Places",
                    systemImage: "mappin.slash",
                    description: Text("Save places in \(destinationName) from Explore or by long-pressing the map.")
                )
            } else {
                VStack(spacing: 0) {
                    Picker("Saved place filter", selection: $selectedFilter) {
                        ForEach(SavedPlacesFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    .accessibilityHint("Filters the saved places list by itinerary origin.")

                    if filteredPlaces.isEmpty {
                        ContentUnavailableView(
                            "No Matching Places",
                            systemImage: "line.3.horizontal.decrease.circle",
                            description: Text(emptyFilterMessage)
                        )
                    } else {
                        List {
                            ForEach(orderedCategories, id: \.self) { category in
                                Section {
                                    ForEach(sortedPlaces(in: category)) { place in
                                        Button {
                                            onSelectPlace(place)
                                        } label: {
                                            HStack(alignment: .top, spacing: 12) {
                                                Image(systemName: categoryIcon(for: place.category))
                                                    .font(.subheadline)
                                                    .foregroundStyle(categoryTint(for: place.category))
                                                    .frame(width: 18)
                                                    .accessibilityHidden(true)

                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(place.name)
                                                        .font(.headline)
                                                        .multilineTextAlignment(.leading)

                                                    HStack(spacing: 8) {
                                                        if place.isItineraryDerived {
                                                            Text("From itinerary")
                                                                .font(.caption2.weight(.semibold))
                                                                .padding(.horizontal, 8)
                                                                .padding(.vertical, 4)
                                                                .background(
                                                                    Color.accentColor.opacity(0.14),
                                                                    in: Capsule(style: .continuous)
                                                                )
                                                                .foregroundStyle(Color.accentColor)
                                                        }

                                                        Text(place.createdAt, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                                                            .font(.caption)
                                                            .foregroundStyle(.secondary)
                                                    }
                                                }
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityElement(children: .combine)
                                        .accessibilityLabel(accessibilityLabel(for: place))
                                        .accessibilityHint("Shows this saved place on the map.")
                                    }
                                } header: {
                                    Text(categoryTitle(for: category))
                                        .accessibilityAddTraits(.isHeader)
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                }
            }
        }
        .navigationTitle("Saved Places")
    }

    private var emptyFilterMessage: String {
        switch selectedFilter {
        case .all:
            return "Save places in \(destinationName) from Explore or by long-pressing the map."
        case .itinerary:
            return "Save itinerary activities from Plan to see them here."
        case .other:
            return "Places saved from the map or Explore will appear here."
        }
    }

    private func categoryTitle(for category: POICategory?) -> String {
        category?.displayName ?? "Other"
    }

    private func sortedPlaces(in category: POICategory?) -> [SavedPlace] {
        (groupedPlaces[category] ?? [])
            .sorted { $0.createdAt > $1.createdAt }
    }

    private func accessibilityLabel(for place: SavedPlace) -> String {
        let categoryName = categoryTitle(for: place.category).lowercased()
        if place.isItineraryDerived {
            return "\(place.name), \(categoryName), from itinerary, \(place.destinationName)"
        }
        return "\(place.name), \(categoryTitle(for: place.category)), \(place.destinationName)"
    }

    private func categoryIcon(for category: POICategory?) -> String {
        category?.icon ?? "mappin.circle.fill"
    }

    private func categoryTint(for category: POICategory?) -> Color {
        switch category {
        case .food:
            return .orange
        case .cafes:
            return .brown
        case .sights:
            return .blue
        case .shopping:
            return .pink
        case .nightlife:
            return .purple
        case nil:
            return .red
        }
    }
}

#Preview {
    NavigationStack {
        SavedPlacesListView(
            destinationName: "Paris",
            savedPlaces: [
                SavedPlace(name: "Eiffel Tower", category: .sights, destinationName: "Paris", latitude: 48.8584, longitude: 2.2945),
                SavedPlace(name: "Cafe de Flore", category: .cafes, destinationName: "Paris", latitude: 48.8546, longitude: 2.3339),
                SavedPlace(name: "Dropped Pin", destinationName: "Paris", latitude: 48.8606, longitude: 2.3376)
            ],
            onSelectPlace: { _ in }
        )
    }
}
