import SwiftUI
import SwiftData

struct DestinationPickerView: View {
    @AppStorage("selectedDestinationName") private var selectedDestinationName = ""

    @Query(sort: [SortDescriptor(\Trip.destinationName, order: .forward)])
    private var trips: [Trip]

    init() {}

    var body: some View {
        Group {
            if trips.isEmpty {
                ContentUnavailableView(
                    "No Destinations Available",
                    systemImage: "airplane",
                    description: Text("Destinations are still loading. Please try again in a moment.")
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
    }

    private var uniqueTrips: [Trip] {
        var seenDestinations = Set<String>()
        return trips.filter { trip in
            seenDestinations.insert(trip.destinationName).inserted
        }
    }
}

#Preview {
    NavigationStack {
        DestinationPickerView()
    }
}
