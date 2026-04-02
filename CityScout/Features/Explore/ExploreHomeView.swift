import SwiftUI
import SwiftData

struct ExploreHomeView: View {
    let destinationName: String

    @Query private var savedPlaces: [SavedPlace]

    @State private var selectedCategory: POICategory? = nil

    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 12)
    ]

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

    private var filteredPOIs: [PointOfInterest] {
        guard let selectedCategory else { return destinationPOIs }
        return destinationPOIs.filter { $0.category == selectedCategory }
    }

    private var topPicks: [PointOfInterest] {
        let picks = destinationPOIs.filter(\.isTopPick)
        guard let selectedCategory else { return picks }
        return picks.filter { $0.category == selectedCategory }
    }

    private func isSaved(_ poi: PointOfInterest) -> Bool {
        SavedPlaceService.isPlaceSaved(
            name: poi.name,
            destinationName: destinationName,
            in: savedPlaces
        )
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

                    if topPicks.isEmpty == false {
                        topPicksSection
                    }

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
                                    POITileView(poi: poi, isSaved: isSaved(poi))
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

    private var topPicksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Picks")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(topPicks) { poi in
                        NavigationLink {
                            POIDetailView(poi: poi, destinationName: destinationName)
                        } label: {
                            TopPickCardView(poi: poi, isSaved: isSaved(poi))
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(poi.name), \(poi.category.displayName.lowercased()), \(destinationName), top pick")
                        .accessibilityHint("Opens details and save option.")
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

private struct POITileView: View {
    let poi: PointOfInterest
    let isSaved: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Image(systemName: poi.symbolName)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)

                Spacer(minLength: 8)

                if isSaved {
                    Label("Saved", systemImage: "bookmark.fill")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.brandSage.opacity(0.2), in: Capsule(style: .continuous))
                        .foregroundStyle(Color.brandGreenDark)
                }
            }

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

private struct TopPickCardView: View {
    let poi: PointOfInterest
    let isSaved: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Image(systemName: poi.symbolName)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)

                Spacer(minLength: 8)

                if isSaved {
                    Image(systemName: "bookmark.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.brandGreenDark)
                        .padding(8)
                        .background(Color.brandSage.opacity(0.18), in: Circle())
                }
            }

            Text(poi.name)
                .font(.headline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Label(poi.category.displayName, systemImage: poi.category.icon)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 180, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    NavigationStack {
        ExploreHomeView(destinationName: "Paris")
    }
}
