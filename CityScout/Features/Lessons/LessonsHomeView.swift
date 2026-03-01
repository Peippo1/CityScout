import SwiftUI
import SwiftData

struct LessonsHomeView: View {
    let destinationName: String

    @Query(sort: [SortDescriptor(\Trip.createdAt, order: .forward)])
    private var trips: [Trip]

    init(destinationName: String) {
        self.destinationName = destinationName
    }

    private var selectedTrip: Trip? {
        trips.first { $0.destinationName == destinationName }
    }

    var body: some View {
        Group {
            if let trip = selectedTrip {
                TripLessonsView(trip: trip)
                    .navigationTitle("Lessons")
            } else {
                ContentUnavailableView(
                    "No Lessons Found",
                    systemImage: "book",
                    description: Text("No trip content is available for \(destinationName) yet.")
                )
                .navigationTitle("Lessons")
            }
        }
    }
}

#Preview {
    NavigationStack {
        LessonsHomeView(destinationName: "Barcelona")
    }
    .modelContainer(LessonsHomeView.previewContainer)
}

private extension LessonsHomeView {
    static var previewContainer: ModelContainer {
        let schema = Schema([Trip.self, Situation.self, Phrase.self, SavedPhrase.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext

        let trip = Trip(destinationName: "Barcelona", baseLanguage: "English", targetLanguage: "Spanish")
        let situation = Situation(trip: trip, title: "Café", sortOrder: 0)
        let phrase = Phrase(
            situation: situation,
            targetText: "Un café con leche, por favor.",
            englishMeaning: "A coffee with milk, please.",
            notes: "Polite and common in cafes.",
            tagsCSV: "food,polite"
        )

        context.insert(trip)
        context.insert(situation)
        context.insert(phrase)

        try? context.save()
        return container
    }
}
