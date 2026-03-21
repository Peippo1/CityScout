import SwiftUI

struct TripShellView: View {
    @AppStorage("selectedDestinationName") private var selectedDestinationName = ""

    let destinationName: String

    var body: some View {
        TabView {
            NavigationStack {
                LessonsHomeView(destinationName: destinationName)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Change City") {
                                selectedDestinationName = ""
                            }
                            .accessibilityLabel("Change city")
                            .accessibilityHint("Returns to destination selection.")
                        }
                    }
            }
            .tabItem {
                Label("Lessons", systemImage: "book")
            }

            NavigationStack {
                PhrasebookHomeView(destinationName: destinationName)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Change City") {
                                selectedDestinationName = ""
                            }
                            .accessibilityLabel("Change city")
                            .accessibilityHint("Returns to destination selection.")
                        }
                    }
            }
            .tabItem {
                Label("Phrasebook", systemImage: "text.book.closed")
            }

            NavigationStack {
                TranslateHomeView(destinationName: destinationName)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Change City") {
                                selectedDestinationName = ""
                            }
                            .accessibilityLabel("Change city")
                            .accessibilityHint("Returns to destination selection.")
                        }
                    }
            }
            .tabItem {
                Label("Translate", systemImage: "globe")
            }

            NavigationStack {
                ExploreHomeView(destinationName: destinationName)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Change City") {
                                selectedDestinationName = ""
                            }
                            .accessibilityLabel("Change city")
                            .accessibilityHint("Returns to destination selection.")
                        }
                    }
            }
            .tabItem {
                Label("Explore", systemImage: "map")
            }

            NavigationStack {
                SearchHomeView(destinationName: destinationName)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Change City") {
                                selectedDestinationName = ""
                            }
                            .accessibilityLabel("Change city")
                            .accessibilityHint("Returns to destination selection.")
                        }
                    }
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }

            NavigationStack {
                PlanHomeView(destinationName: destinationName)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Change City") {
                                selectedDestinationName = ""
                            }
                            .accessibilityLabel("Change city")
                            .accessibilityHint("Returns to destination selection.")
                        }
                    }
            }
            .tabItem {
                Label("Plan", systemImage: "calendar")
            }

            NavigationStack {
                MapHomeView(destinationName: destinationName)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Change City") {
                                selectedDestinationName = ""
                            }
                            .accessibilityLabel("Change city")
                            .accessibilityHint("Returns to destination selection.")
                        }
                    }
            }
            .tabItem {
                Label("Map", systemImage: "map")
            }
        }
    }
}

#Preview {
    TripShellView(destinationName: "Paris")
}
