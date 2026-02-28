import SwiftUI
import SwiftData

struct TripsHomeView: View {
    @Query(sort: [SortDescriptor(\Trip.createdAt, order: .forward)])
    private var trips: [Trip]

    var body: some View {
        Group {
            if trips.isEmpty {
                ContentUnavailableView(
                    "No Trips Yet",
                    systemImage: "airplane",
                    description: Text("Seed content has not been imported yet.")
                )
            } else {
                List(trips) { trip in
                    NavigationLink {
                        TripLessonsView(trip: trip)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(trip.destinationName)
                                .font(.headline)
                            Text(trip.targetLanguage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            debugLog("Trip tapped: \(trip.destinationName) (\(trip.id.uuidString))")
                        }
                    )
                }
            }
        }
    }
}
