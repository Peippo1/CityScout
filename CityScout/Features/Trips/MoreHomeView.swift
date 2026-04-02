import SwiftData
import SwiftUI

struct MoreHomeView: View {
    @AppStorage("selectedDestinationName") private var selectedDestinationName = ""

    let destinationName: String

    @Query(sort: [SortDescriptor(\SavedPlace.createdAt, order: .reverse)])
    private var savedPlaces: [SavedPlace]
    @Query(sort: [SortDescriptor(\SavedPhrase.createdAt, order: .reverse)])
    private var savedPhrases: [SavedPhrase]
    @Query(sort: [SortDescriptor(\SavedItinerary.createdAt, order: .reverse)])
    private var savedItineraries: [SavedItinerary]

    private var destinationSavedPlaces: [SavedPlace] {
        savedPlaces.filter { $0.destinationName == destinationName }
    }

    private var destinationSavedPhrases: [SavedPhrase] {
        savedPhrases.filter { $0.destinationName == destinationName }
    }

    private var destinationSavedItineraries: [SavedItinerary] {
        savedItineraries.filter { $0.destinationName == destinationName }
    }

    private var recentActivitySummary: String {
        let recentEntries: [(date: Date, label: String)] =
            destinationSavedPlaces.map { ($0.createdAt, "Saved place") }
            + destinationSavedPhrases.map { ($0.createdAt, "Saved phrase") }
            + destinationSavedItineraries.map { ($0.createdAt, "Saved itinerary") }

        guard let latestEntry = recentEntries.max(by: { $0.date < $1.date }) else {
            return "No saved activity yet"
        }

        return "\(latestEntry.label) • \(latestEntry.date.formatted(date: .abbreviated, time: .shortened))"
    }

    var body: some View {
        List {
            Section {
                TripHubCard(
                    destinationName: destinationName,
                    savedPlacesCount: destinationSavedPlaces.count,
                    savedPhrasesCount: destinationSavedPhrases.count,
                    savedItinerariesCount: destinationSavedItineraries.count,
                    recentActivitySummary: recentActivitySummary
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } header: {
                Text("Trip Hub")
            }

            Section("Discover") {
                NavigationLink {
                    LessonsHomeView(destinationName: destinationName)
                } label: {
                    MoreRow(
                        title: "Lessons",
                        subtitle: "Practice essentials for \(destinationName)",
                        systemImage: "book"
                    )
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Lessons")
                .accessibilityHint("Opens lesson practice for \(destinationName).")

                NavigationLink {
                    ExploreHomeView(destinationName: destinationName)
                } label: {
                    MoreRow(
                        title: "Explore",
                        subtitle: "Browse curated places",
                        systemImage: "map"
                    )
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Explore")
                .accessibilityHint("Shows points of interest in \(destinationName).")

                NavigationLink {
                    SearchHomeView(destinationName: destinationName)
                } label: {
                    MoreRow(
                        title: "Search",
                        subtitle: "Find spots and saved places",
                        systemImage: "magnifyingglass"
                    )
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Search")
                .accessibilityHint("Searches places and saved spots in \(destinationName).")
            }

            Section("Saved") {
                NavigationLink {
                    TodayHomeView(destinationName: destinationName)
                } label: {
                    MoreRow(
                        title: "Today",
                        subtitle: "Work through today’s saved plan",
                        systemImage: "sun.max"
                    )
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Today")
                .accessibilityHint("Opens today mode for \(destinationName).")

                NavigationLink {
                    PlanHomeView(destinationName: destinationName)
                } label: {
                    MoreRow(
                        title: "Saved Itineraries",
                        subtitle: "Revisit your planned days",
                        systemImage: "bookmark"
                    )
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Saved itineraries")
                .accessibilityHint("Opens your saved itineraries for \(destinationName).")
            }

            Section("City") {
                Button {
                    selectedDestinationName = ""
                } label: {
                    MoreRow(
                        title: "Change City",
                        subtitle: "Pick a new destination",
                        systemImage: "arrow.triangle.2.circlepath"
                    )
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Change city")
                .accessibilityHint("Returns to destination selection.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("More")
        .safeAreaInset(edge: .top) {
            CityHeaderView(destinationName: destinationName)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .background(.regularMaterial)
        }
    }
}

private struct TripHubCard: View {
    let destinationName: String
    let savedPlacesCount: Int
    let savedPhrasesCount: Int
    let savedItinerariesCount: Int
    let recentActivitySummary: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("\(destinationName) at a glance")
                .font(.headline)

            HStack(spacing: 12) {
                hubStat(title: "Places", value: savedPlacesCount, tint: .brandSage)
                hubStat(title: "Phrases", value: savedPhrasesCount, tint: .brandPink)
                hubStat(title: "Plans", value: savedItinerariesCount, tint: .brandGreenDark)
            }

            Label(recentActivitySummary, systemImage: "clock")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.brandSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.brandSage.opacity(0.12), lineWidth: 1)
        )
    }

    private func hubStat(title: String, value: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value.formatted())
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct MoreRow: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 22)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.leading)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        MoreHomeView(destinationName: "Paris")
    }
}
