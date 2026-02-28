import SwiftUI
import SwiftData

struct TripLessonsView: View {
    let trip: Trip

    @Query(
        sort: [
            SortDescriptor(\Situation.sortOrder, order: .forward),
            SortDescriptor(\Situation.title, order: .forward)
        ]
    )
    private var allSituations: [Situation]
    @State private var didCompleteInitialLoad = false

    private var situations: [Situation] {
        let tripID = trip.id
        return allSituations.filter { $0.trip.id == tripID }
    }

    init(trip: Trip) {
        self.trip = trip
        debugLog("TripLessonsView init for trip '\(trip.destinationName)' (\(trip.id.uuidString))")
    }

    var body: some View {
        List {
            if situations.isEmpty {
                ContentUnavailableView(
                    "No Situations",
                    systemImage: "exclamationmark.triangle",
                    description: Text("This trip has no situations yet.")
                )
            } else {
                ForEach(situations) { situation in
                    NavigationLink {
                        SituationDetailView(situation: situation, destinationName: trip.destinationName)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(situation.title)
                            Text("Micro-lesson")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(trip.destinationName)
        .task {
            guard didCompleteInitialLoad == false else { return }
            didCompleteInitialLoad = true
            debugLog("TripLessonsView loaded \(situations.count) situations for trip \(trip.id.uuidString)")
        }
        .debugSafetyTimeout("TripLessonsView(\(trip.id.uuidString))", completed: $didCompleteInitialLoad)
    }
}
