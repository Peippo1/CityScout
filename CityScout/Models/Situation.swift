import Foundation
import SwiftData

@Model
final class Situation {
    var id: UUID
    var trip: Trip
    var title: String
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        trip: Trip,
        title: String,
        sortOrder: Int
    ) {
        self.id = id
        self.trip = trip
        self.title = title
        self.sortOrder = sortOrder
    }
}
