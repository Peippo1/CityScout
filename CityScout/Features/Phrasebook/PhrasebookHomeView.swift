import SwiftUI
import SwiftData

struct PhrasebookHomeView: View {
    let destinationName: String

    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""

    @Query(sort: [SortDescriptor(\SavedPhrase.createdAt, order: .reverse)])
    private var savedPhrases: [SavedPhrase]
    @Query(
        filter: #Predicate { $0.lastPracticedAt != nil },
        sort: [SortDescriptor(\SavedPhrase.lastPracticedAt, order: .reverse)]
    )
    private var recentPracticed: [SavedPhrase]

    init(destinationName: String) {
        self.destinationName = destinationName
    }

    private var destinationSavedPhrases: [SavedPhrase] {
        savedPhrases.filter { $0.destinationName == destinationName }
    }

    private var destinationRecentPracticed: [SavedPhrase] {
        recentPracticed.filter { $0.destinationName == destinationName }
    }

    private var filteredSavedPhrases: [SavedPhrase] {
        guard !searchText.isEmpty else { return destinationSavedPhrases }
        return destinationSavedPhrases.filter(matchesSearch)
    }

    private var filteredRecentPracticed: [SavedPhrase] {
        guard !searchText.isEmpty else { return destinationRecentPracticed }
        return destinationRecentPracticed.filter(matchesSearch)
    }

    var body: some View {
        Group {
            if destinationSavedPhrases.isEmpty {
                ContentUnavailableView(
                    "No Saved Phrases",
                    systemImage: "text.book.closed",
                    description: Text("Save a phrase from Lessons in \(destinationName) to see it here.")
                )
            } else if filteredSavedPhrases.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List {
                    if !filteredRecentPracticed.isEmpty {
                        Section("Recently Practiced") {
                            ForEach(filteredRecentPracticed.prefix(5)) { savedPhrase in
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
                        }
                    }

                    ForEach(filteredSavedPhrases) { savedPhrase in
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
        .searchable(text: $searchText, prompt: "Search phrases")
        .toolbar {
            if !destinationSavedPhrases.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
        }
    }

    private func matchesSearch(_ savedPhrase: SavedPhrase) -> Bool {
        savedPhrase.targetText.localizedCaseInsensitiveContains(searchText)
            || savedPhrase.englishMeaning.localizedCaseInsensitiveContains(searchText)
    }

    private func deleteSavedPhrases(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredSavedPhrases[index])
        }

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to delete saved phrase(s): \(error.localizedDescription)")
        }
    }
}
