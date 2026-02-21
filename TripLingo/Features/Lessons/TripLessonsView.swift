import SwiftUI
import SwiftData

struct TripLessonsView: View {
    let trip: Trip

    @Query private var situations: [Situation]

    init(trip: Trip) {
        self.trip = trip
        let tripID = trip.id
        _situations = Query(
            filter: #Predicate<Situation> { situation in
                situation.trip.id == tripID
            },
            sort: [
                SortDescriptor(\Situation.sortOrder, order: .forward),
                SortDescriptor(\Situation.title, order: .forward)
            ]
        )
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
    }
}
