import SwiftUI
import SwiftData

struct SituationDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let situation: Situation
    let destinationName: String

    // Fetch phrases for this situation
    @Query private var phrases: [Phrase]

    init(situation: Situation, destinationName: String) {
        self.situation = situation
        self.destinationName = destinationName

        let situationID = situation.id

        self._phrases = Query(
            filter: #Predicate<Phrase> { phrase in
                phrase.situation.id == situationID
            },
            sort: [SortDescriptor(\Phrase.targetText, order: .forward)]
        )
    }

    var body: some View {
        List {
            if phrases.isEmpty {
                ContentUnavailableView(
                    "No Phrases",
                    systemImage: "quote.bubble",
                    description: Text("This situation has no phrases yet.")
                )
            } else {
                Section {
                    ForEach(phrases) { phrase in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(phrase.targetText)
                                .font(.headline)
                            Text(phrase.englishMeaning)
                                .foregroundStyle(.secondary)
                            if let notes = phrase.notes, notes.isEmpty == false {
                                Text(notes)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            HStack(spacing: 8) {
                                ForEach(tags(from: phrase.tagsCSV), id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(.thinMaterial, in: Capsule())
                                }
                            }
                            .padding(.top, 2)

                            HStack {
                                Spacer()
                                Button {
                                    savePhrase(phrase)
                                } label: {
                                    Label(isPhraseSaved(phrase) ? "Saved" : "Save", systemImage: isPhraseSaved(phrase) ? "bookmark.fill" : "bookmark")
                                }
                                .buttonStyle(.bordered)
                                .disabled(isPhraseSaved(phrase))
                            }
                        }
                        .padding(.vertical, 6)
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(destinationName)
                        Text("Phrases")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(situation.title)
    }

    private func tags(from csv: String) -> [String] {
        csv.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
    }

    private func savePhrase(_ phrase: Phrase) {
        do {
            _ = try SavedPhraseService.saveIfNeeded(
                modelContext: modelContext,
                destinationName: destinationName,
                situationTitle: situation.title,
                targetText: phrase.targetText,
                englishMeaning: phrase.englishMeaning
            )
        } catch {
            assertionFailure("Failed to save phrase: \(error.localizedDescription)")
        }
    }

    private func isPhraseSaved(_ phrase: Phrase) -> Bool {
        SavedPhraseService.isSaved(
            modelContext: modelContext,
            destinationName: destinationName,
            situationTitle: situation.title,
            targetText: phrase.targetText
        )
    }
}

#Preview {
    // In-memory model container with sample data for preview
    let schema = Schema([Trip.self, Situation.self, Phrase.self, SavedPhrase.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    let context = container.mainContext

    let trip = Trip(destinationName: "Barcelona", baseLanguage: "English", targetLanguage: "Spanish")
    let situation = Situation(trip: trip, title: "Café", sortOrder: 0)
    let phrase1 = Phrase(situation: situation, targetText: "Un café con leche, por favor.", englishMeaning: "A coffee with milk, please.", notes: "Polite and common in cafes.", tagsCSV: "food,polite")
    let phrase2 = Phrase(situation: situation, targetText: "¿Cuánto cuesta?", englishMeaning: "How much does it cost?", notes: nil, tagsCSV: "shopping")

    context.insert(trip)
    context.insert(situation)
    context.insert(phrase1)
    context.insert(phrase2)
    try? context.save()

    return NavigationStack {
        SituationDetailView(situation: situation, destinationName: trip.destinationName)
    }
    .modelContainer(container)
}
