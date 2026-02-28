import Foundation
import SwiftData

@Model
final class Phrase {
    var id: UUID
    var situation: Situation
    var targetText: String
    var englishMeaning: String
    var notes: String?
    var tagsCSV: String

    init(
        id: UUID = UUID(),
        situation: Situation,
        targetText: String,
        englishMeaning: String,
        notes: String? = nil,
        tagsCSV: String = ""
    ) {
        self.id = id
        self.situation = situation
        self.targetText = targetText
        self.englishMeaning = englishMeaning
        self.notes = notes
        self.tagsCSV = tagsCSV
    }
}
