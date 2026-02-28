import SwiftUI
import SwiftData

struct SavedPhraseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let savedPhrase: SavedPhrase

    @State private var showDeleteConfirmation = false

    var body: some View {
        List {
            Section("Target") {
                Text(savedPhrase.targetText)
                    .font(.title3)
            }

            Section("Meaning") {
                Text(savedPhrase.englishMeaning)
            }

            Section("Context") {
                Text(savedPhrase.destinationName)
                Text(savedPhrase.situationTitle)
            }

            Section("Saved") {
                Text(savedPhrase.createdAt, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
            }

            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Text("Delete Phrase")
                }
            }
        }
        .navigationTitle("Saved Phrase")
        .confirmationDialog(
            "Delete this saved phrase?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteSavedPhrase()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func deleteSavedPhrase() {
        modelContext.delete(savedPhrase)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            assertionFailure("Failed to delete saved phrase: \(error.localizedDescription)")
        }
    }
}
