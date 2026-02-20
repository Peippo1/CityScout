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

        if try modelContext.fetch(descriptor).isEmpty == false {
            return false
        }

        let saved = SavedPhrase(
            targetText: targetText,
            englishMeaning: englishMeaning,
            destinationName: destinationName,
            situationTitle: situationTitle
        )
        modelContext.insert(saved)
        try modelContext.save()
        return true
    }
}
