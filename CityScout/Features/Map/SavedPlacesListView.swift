import SwiftUI

struct SavedPlacesListView: View {
    let destinationName: String
    let savedPlaces: [SavedPlace]
    let onSelectPlace: (SavedPlace) -> Void

    private static let categoryOrder: [POICategory?] = [
        .food,
        .cafes,
        .sights,
        .shopping,
        .nightlife,
        nil
    ]

    private var groupedPlaces: [POICategory?: [SavedPlace]] {
        Dictionary(grouping: savedPlaces) { $0.category }
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
                List {
                    ForEach(orderedCategories, id: \.self) { category in
                        Section {
                            ForEach(sortedPlaces(in: category)) { place in
                                Button {
                                    onSelectPlace(place)
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(place.name)
                                            .font(.headline)
                                            .multilineTextAlignment(.leading)

                                        Text(place.createdAt, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("\(place.name), \(categoryTitle(for: category))")
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
        .navigationTitle("Saved Places")
    }

    private func categoryTitle(for category: POICategory?) -> String {
        category?.displayName ?? "Other"
    }

    private func sortedPlaces(in category: POICategory?) -> [SavedPlace] {
        (groupedPlaces[category] ?? [])
            .sorted { $0.createdAt > $1.createdAt }
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
