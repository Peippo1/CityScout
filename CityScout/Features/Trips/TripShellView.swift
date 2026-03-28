import SwiftUI

struct TripShellView: View {
    @AppStorage("selectedDestinationName") private var selectedDestinationName = ""

    let destinationName: String

    var body: some View {
        TabView {
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
                MoreHomeView(destinationName: destinationName)
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
                Label("More", systemImage: "ellipsis.circle")
            }
        }
    }
}

#Preview {
    TripShellView(destinationName: "Paris")
}
