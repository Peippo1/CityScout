import SwiftUI
import SwiftData

struct DestinationPickerView: View {
    @AppStorage("selectedDestinationName") private var selectedDestinationName = ""
    @AppStorage("hasSeeded_v1") private var hasSeeded = false
    @AppStorage("seedErrorMessage") private var persistedSeedErrorMessage = ""

    @Query(sort: [SortDescriptor(\Trip.destinationName, order: .forward)])
    private var trips: [Trip]

    @State private var isSeeding = true
    @State private var seedError: String?

    init() {}

    var body: some View {
        Group {
            if let seedError {
                ContentUnavailableView(
                    "Failed to load destinations",
                    systemImage: "exclamationmark.triangle",
                    description: Text(seedError)
                )
            } else if trips.isEmpty, isSeeding {
                ContentUnavailableView(
                    "No Destinations Available",
                    systemImage: "airplane",
                    description: Text("Destinations are still loading. Please try again in a moment.")
                )
            } else if trips.isEmpty, isSeeding == false {
                ContentUnavailableView(
                    "No Destinations Found",
                    systemImage: "airplane.circle",
                    description: Text("Seed import finished, but no destinations were found.")
                )
            } else {
                List(uniqueTrips) { trip in
                    Button {
                        selectedDestinationName = trip.destinationName
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(trip.destinationName)
                                .font(.headline)
                            Text(trip.targetLanguage)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityLabel("Choose \(trip.destinationName)")
                    .accessibilityHint("Opens features for this destination.")
                }
            }
        }
        .navigationTitle("Where are you going?")
        .onAppear(perform: refreshSeedState)
        .onChange(of: hasSeeded) { _, _ in refreshSeedState() }
        .onChange(of: trips.count) { _, _ in refreshSeedState() }
        .onChange(of: persistedSeedErrorMessage) { _, _ in refreshSeedState() }
    }

    private var uniqueTrips: [Trip] {
        var seenDestinations = Set<String>()
        return trips.filter { trip in
            seenDestinations.insert(trip.destinationName).inserted
        }
    }

    private func refreshSeedState() {
        if persistedSeedErrorMessage.isEmpty == false {
            seedError = persistedSeedErrorMessage
            isSeeding = false
            return
        }

        if hasSeeded || trips.isEmpty == false {
            seedError = nil
            isSeeding = false
            return
        }

        isSeeding = true
    }
}

#Preview {
    NavigationStack {
        DestinationPickerView()
    }
}
