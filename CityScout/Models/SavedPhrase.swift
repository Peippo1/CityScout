import Foundation
import SwiftData

@Model
final class SavedPhrase {
    var id: UUID
    var createdAt: Date
    var targetText: String
    var englishMeaning: String
    var destinationName: String
    var situationTitle: String
    var lastPracticedAt: Date?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        targetText: String,
        englishMeaning: String,
        destinationName: String,
        situationTitle: String,
        lastPracticedAt: Date? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.targetText = targetText
        self.englishMeaning = englishMeaning
        self.destinationName = destinationName
        self.situationTitle = situationTitle
        self.lastPracticedAt = lastPracticedAt
    }
}
