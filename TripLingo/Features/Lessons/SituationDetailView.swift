import SwiftUI
import SwiftData

struct SituationDetailView: View {
    let situation: Situation
    let destinationName: String

    @Query private var phrases: [Phrase]

    init(situation: Situation, destinationName: String) {
        self.situation = situation
        self.destinationName = destinationName
        _phrases = Query(
            filter: #Predicate<Phrase> { phrase in
                phrase.situation == situation
            },
            sort: [SortDescriptor(\Phrase.targetText, order: .forward)]
        )
    }

    var body: some View {
        List {
            if phrases.isEmpty {
                ContentUnavailableView(
                    "No Phrases Yet",
                    systemImage: "text.bubble",
                    description: Text("Phrases for this situation are not available yet.")
                )
            } else {
                Section("Phrases") {
                    ForEach(phrases) { phrase in
                        NavigationLink {
                            PhraseDetailView(
                                phrase: phrase,
                                destinationName: destinationName,
                                situationTitle: situation.title
                            )
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(phrase.targetText)
                                Text(phrase.englishMeaning)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(situation.title)
    }
}

#Preview {
    NavigationStack {
        SituationDetailView(situation: previewSituation, destinationName: "Barcelona")
    }
    .modelContainer(Self.previewContainer)
}

private extension SituationDetailView {
    static let previewContainer: ModelContainer = {
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
    }()

    static var previewSituation: Situation {
        let descriptor = FetchDescriptor<Situation>()
        return try! previewContainer.mainContext.fetch(descriptor).first!
    }
}
