import SwiftUI

struct MoreHomeView: View {
    @AppStorage("selectedDestinationName") private var selectedDestinationName = ""

    let destinationName: String

    var body: some View {
        List {
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
