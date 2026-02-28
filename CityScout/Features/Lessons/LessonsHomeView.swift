import SwiftUI
import SwiftData

struct LessonsHomeView: View {
    var body: some View {
        TripsHomeView()
            .navigationTitle("Lessons")
    }
}

#Preview {
    NavigationStack {
        LessonsHomeView()
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
