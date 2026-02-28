import Foundation
import SwiftData

enum SeedContentImporter {
    static func importIfNeeded(modelContext: ModelContext, seedName: String) throws {
        let dto = try SeedContentLoader.loadTrip(seedName: seedName)

        let destination = dto.destination.trimmingCharacters(in: .whitespacesAndNewlines)
        let targetLanguage = dto.languages.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Spanish"
        let baseLanguage = "English"

        if try tripExists(
            destinationName: destination,
            targetLanguage: targetLanguage,
            modelContext: modelContext
        ) {
            return
        }

        let trip = Trip(
            destinationName: destination,
            baseLanguage: baseLanguage,
            targetLanguage: targetLanguage
        )
        modelContext.insert(trip)

        for (situationIndex, situationDTO) in dto.situations.enumerated() {
            let situation = Situation(
                trip: trip,
                title: situationDTO.title,
                sortOrder: situationIndex
            )
            modelContext.insert(situation)

            for phraseDTO in situationDTO.phrases {
                let phrase = Phrase(
                    situation: situation,
                    targetText: phraseDTO.targetText,
                    englishMeaning: phraseDTO.englishMeaning,
                    notes: phraseDTO.notes,
                    tagsCSV: phraseDTO.tags.joined(separator: ",")
                )
                modelContext.insert(phrase)
            }
        }

        try modelContext.save()
    }

    private static func tripExists(
        destinationName: String,
        targetLanguage: String,
        modelContext: ModelContext
    ) throws -> Bool {
        let descriptor = FetchDescriptor<Trip>(
            predicate: #Predicate { trip in
                trip.destinationName == destinationName && trip.targetLanguage == targetLanguage
            }
        )

        return try modelContext.fetch(descriptor).isEmpty == false
    }
}
