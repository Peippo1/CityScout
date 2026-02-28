import Foundation
import SwiftData

@Model
final class Trip {
    var id: UUID
    var destinationName: String
    var baseLanguage: String
    var targetLanguage: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        destinationName: String,
        baseLanguage: String,
        targetLanguage: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.destinationName = destinationName
        self.baseLanguage = baseLanguage
        self.targetLanguage = targetLanguage
        self.createdAt = createdAt
    }
}
