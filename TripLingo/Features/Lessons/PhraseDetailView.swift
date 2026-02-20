import SwiftUI
import SwiftData
import UIKit

struct PhraseDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let phrase: Phrase
    let destinationName: String
    let situationTitle: String

    @State private var isSaved = false

    var body: some View {
        List {
            Section("Target") {
                Text(phrase.targetText)
                    .font(.title3)
            }

            Section("Meaning") {
                Text(phrase.englishMeaning)
            }

            if let notes = phrase.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                }
            }

            Section {
                Button(isSaved ? "Saved" : "Save to Phrasebook") {
                    savePhrase()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaved)
            }
        }
        .navigationTitle("Phrase")
        .onAppear {
            refreshSavedState()
        }
    }

    private func refreshSavedState() {
        let targetText = phrase.targetText
        let destination = destinationName
        let situation = situationTitle
        let descriptor = FetchDescriptor<SavedPhrase>(
            predicate: #Predicate { saved in
                saved.targetText == targetText &&
                saved.destinationName == destination &&
                saved.situationTitle == situation
            }
        )

        do {
            isSaved = try modelContext.fetch(descriptor).isEmpty == false
        } catch {
            isSaved = false
        }
    }

    private func savePhrase() {
        let targetText = phrase.targetText
        let destination = destinationName
        let situation = situationTitle
        let descriptor = FetchDescriptor<SavedPhrase>(
            predicate: #Predicate { saved in
                saved.targetText == targetText &&
                saved.destinationName == destination &&
                saved.situationTitle == situation
            }
        )

        do {
            if try modelContext.fetch(descriptor).isEmpty {
                let saved = SavedPhrase(
                    targetText: phrase.targetText,
                    englishMeaning: phrase.englishMeaning,
                    destinationName: destinationName,
                    situationTitle: situationTitle
                )
                modelContext.insert(saved)
                try modelContext.save()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            refreshSavedState()
        } catch {
            assertionFailure("Failed to save phrase: \(error.localizedDescription)")
        }
    }
}

#Preview {
    NavigationStack {
        PhraseDetailView(
            phrase: previewPhrase,
            destinationName: "Barcelona",
            situationTitle: "Café"
        )
    }
    .modelContainer(Self.previewContainer)
}

private extension PhraseDetailView {
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

    static var previewPhrase: Phrase {
        let descriptor = FetchDescriptor<Phrase>()
        return try! previewContainer.mainContext.fetch(descriptor).first!
    }
}
