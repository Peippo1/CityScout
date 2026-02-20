import SwiftUI
import SwiftData

struct PhrasebookHomeView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\SavedPhrase.createdAt, order: .reverse)])
    private var savedPhrases: [SavedPhrase]

    var body: some View {
        Group {
            if savedPhrases.isEmpty {
                ContentUnavailableView(
                    "No Saved Phrases",
                    systemImage: "text.book.closed",
                    description: Text("Save a phrase from Lessons to see it here.")
                )
            } else {
                List {
                    ForEach(savedPhrases) { savedPhrase in
                        NavigationLink {
                            SavedPhraseDetailView(savedPhrase: savedPhrase)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(savedPhrase.targetText)
                                    .font(.headline)
                                Text(savedPhrase.englishMeaning)
                                    .foregroundStyle(.secondary)
                                Text("\(savedPhrase.destinationName) • \(savedPhrase.situationTitle)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteSavedPhrases)
                }
            }
        }
        .navigationTitle("Phrasebook")
        .toolbar {
            if !savedPhrases.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
        }
    }

    private func deleteSavedPhrases(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(savedPhrases[index])
        }

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to delete saved phrase(s): \(error.localizedDescription)")
        }
    }
}
