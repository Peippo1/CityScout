import Foundation
import SwiftData

enum SavedPhraseService {
    static func isSaved(
        modelContext: ModelContext,
        destinationName: String,
        situationTitle: String,
        targetText: String
    ) -> Bool {
        let destination = destinationName
        let situation = situationTitle
        let target = targetText

        let descriptor = FetchDescriptor<SavedPhrase>(
            predicate: #Predicate { saved in
                saved.destinationName == destination &&
                saved.situationTitle == situation &&
                saved.targetText == target
            }
        )

        do {
            return try modelContext.fetch(descriptor).isEmpty == false
        } catch {
            return false
        }
    }

    @discardableResult
    static func saveIfNeeded(
        modelContext: ModelContext,
        destinationName: String,
        situationTitle: String,
        targetText: String,
        englishMeaning: String
    ) throws -> Bool {
        let destination = destinationName
        let situation = situationTitle
        let target = targetText

        let descriptor = FetchDescriptor<SavedPhrase>(
            predicate: #Predicate { saved in
                saved.destinationName == destination &&
                saved.situationTitle == situation &&
                saved.targetText == target
            }
        )

        let existing = try modelContext.fetch(descriptor)
        if let saved = existing.first {
            saved.lastPracticedAt = Date()
            saved.englishMeaning = englishMeaning
            try modelContext.save()
            return false
        }

        let saved = SavedPhrase(
            targetText: targetText,
            englishMeaning: englishMeaning,
            destinationName: destinationName,
            situationTitle: situationTitle,
            lastPracticedAt: Date()
        )
        modelContext.insert(saved)
        try modelContext.save()
        return true
    }

    static func markPracticed(
        modelContext: ModelContext,
        destinationName: String,
        situationTitle: String,
        targetText: String
    ) throws {
        let destination = destinationName
        let situation = situationTitle
        let target = targetText

        let descriptor = FetchDescriptor<SavedPhrase>(
            predicate: #Predicate { saved in
                saved.destinationName == destination &&
                saved.situationTitle == situation &&
                saved.targetText == target
            }
        )

        guard let saved = try modelContext.fetch(descriptor).first else { return }
        saved.lastPracticedAt = Date()
        try modelContext.save()
    }
}
