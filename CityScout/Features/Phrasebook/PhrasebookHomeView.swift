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
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        CityHeaderView(destinationName: destinationName)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        ContentUnavailableView(
                            "No Saved Phrases",
                            systemImage: "text.book.closed",
                            description: Text("Save a phrase from Lessons in \(destinationName) to see it here.")
                        )
                        .accessibilityLabel("No saved phrases for \(destinationName)")
                        .accessibilityHint("Save a phrase from Lessons to find it here later.")
                    }
                }
            } else if filteredSavedPhrases.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        CityHeaderView(destinationName: destinationName)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        ContentUnavailableView.search(text: searchText)
                            .accessibilityLabel("No saved phrases match \(searchText)")
                            .accessibilityHint("Try a different search term.")
                    }
                }
            } else {
                List {
                    CityHeaderView(destinationName: destinationName)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)

                    if !filteredRecentPracticed.isEmpty {
                        Section("Recently Practiced") {
                            ForEach(filteredRecentPracticed.prefix(5)) { savedPhrase in
                                NavigationLink {
                                    SavedPhraseDetailView(savedPhrase: savedPhrase)
                                } label: {
                                    phraseRow(
                                        targetText: savedPhrase.targetText,
                                        meaning: savedPhrase.englishMeaning,
                                        metadata: "\(savedPhrase.destinationName) • \(savedPhrase.situationTitle)",
                                        accent: .brandPink
                                    )
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityHint("Opens the saved phrase details.")
                                .listRowBackground(Color.clear)
                            }
                        }
                    }

                    ForEach(filteredSavedPhrases) { savedPhrase in
                        NavigationLink {
                            SavedPhraseDetailView(savedPhrase: savedPhrase)
                        } label: {
                            phraseRow(
                                targetText: savedPhrase.targetText,
                                meaning: savedPhrase.englishMeaning,
                                metadata: "\(savedPhrase.destinationName) • \(savedPhrase.situationTitle)",
                                accent: .brandSage
                            )
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityHint("Opens the saved phrase details.")
                        .listRowBackground(Color.clear)
                    }
                    .onDelete(perform: deleteSavedPhrases)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.brandCream)
            }
        }
        .background(Color.brandCream.ignoresSafeArea())
        .navigationTitle("\(destinationName) Phrasebook")
        .searchable(text: $searchText, prompt: "Search phrases")
        .toolbar {
            if !destinationSavedPhrases.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                        .accessibilityLabel("Edit saved phrases")
                        .accessibilityHint("Lets you delete saved phrases from the list.")
                }
            }
        }
    }

    private func matchesSearch(_ savedPhrase: SavedPhrase) -> Bool {
        savedPhrase.targetText.localizedCaseInsensitiveContains(searchText)
            || savedPhrase.englishMeaning.localizedCaseInsensitiveContains(searchText)
    }

    private func phraseRow(
        targetText: String,
        meaning: String,
        metadata: String,
        accent: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(accent.opacity(0.24))
                .frame(width: 12, height: 12)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 6) {
                Text(targetText)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                Text(meaning)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(metadata)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.brandSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accent.opacity(0.18), lineWidth: 1)
        )
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
