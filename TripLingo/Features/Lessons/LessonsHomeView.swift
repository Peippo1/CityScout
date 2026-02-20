import SwiftUI
import SwiftData

struct LessonsHomeView: View {
    @Query(sort: [SortDescriptor(\Trip.createdAt, order: .forward)])
    private var trips: [Trip]

    @Query(sort: [SortDescriptor(\Situation.sortOrder, order: .forward), SortDescriptor(\Situation.title, order: .forward)])
    private var situations: [Situation]

    private var barcelonaTrip: Trip? {
        trips.first(where: { $0.destinationName.caseInsensitiveCompare("Barcelona") == .orderedSame }) ?? trips.first
    }

    private var barcelonaSituations: [Situation] {
        guard let trip = barcelonaTrip else { return [] }
        return situations.filter { $0.trip == trip }
    }

    var body: some View {
        List {
            if let trip = barcelonaTrip {
                if barcelonaSituations.isEmpty {
                    ContentUnavailableView(
                        "No Situations Found",
                        systemImage: "exclamationmark.triangle",
                        description: Text("Barcelona seed content appears to be missing situation data.")
                    )
                } else {
                    Section {
                        ForEach(barcelonaSituations) { situation in
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
                    } header: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(trip.destinationName)
                            Text("Situation-based micro-lessons")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    "No Lessons Yet",
                    systemImage: "book.closed",
                    description: Text("Seed content will appear after app startup.")
                )
            }
        }
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
