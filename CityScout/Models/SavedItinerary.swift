import Foundation
import SwiftData

@Model
final class SavedItinerary {
    private static let csvSeparator = ","

    var destinationName: String
    var createdAt: Date
    var customTitle: String
    var prompt: String
    var preferencesCSV: String
    var morningTitle: String
    var morningActivitiesCSV: String
    var afternoonTitle: String
    var afternoonActivitiesCSV: String
    var eveningTitle: String
    var eveningActivitiesCSV: String
    var notesCSV: String

    var preferences: [String] {
        get { Self.decodeCSV(preferencesCSV) }
        set { preferencesCSV = Self.encodeCSV(newValue) }
    }

    var morningActivities: [String] {
        get { Self.decodeCSV(morningActivitiesCSV) }
        set { morningActivitiesCSV = Self.encodeCSV(newValue) }
    }

    var afternoonActivities: [String] {
        get { Self.decodeCSV(afternoonActivitiesCSV) }
        set { afternoonActivitiesCSV = Self.encodeCSV(newValue) }
    }

    var eveningActivities: [String] {
        get { Self.decodeCSV(eveningActivitiesCSV) }
        set { eveningActivitiesCSV = Self.encodeCSV(newValue) }
    }

    var notes: [String] {
        get { Self.decodeCSV(notesCSV) }
        set { notesCSV = Self.encodeCSV(newValue) }
    }

    init(
        destinationName: String,
        createdAt: Date = Date(),
        customTitle: String = "",
        prompt: String,
        preferencesCSV: String,
        morningTitle: String,
        morningActivitiesCSV: String,
        afternoonTitle: String,
        afternoonActivitiesCSV: String,
        eveningTitle: String,
        eveningActivitiesCSV: String,
        notesCSV: String
    ) {
        self.destinationName = destinationName
        self.createdAt = createdAt
        self.customTitle = customTitle
        self.prompt = prompt
        self.preferencesCSV = preferencesCSV
        self.morningTitle = morningTitle
        self.morningActivitiesCSV = morningActivitiesCSV
        self.afternoonTitle = afternoonTitle
        self.afternoonActivitiesCSV = afternoonActivitiesCSV
        self.eveningTitle = eveningTitle
        self.eveningActivitiesCSV = eveningActivitiesCSV
        self.notesCSV = notesCSV
    }

    var hasCustomTitle: Bool {
        customTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    static func encodeCSV(_ values: [String]) -> String {
        values
            .map { value in
                let escapedValue = value.replacingOccurrences(of: "\"", with: "\"\"")
                return "\"\(escapedValue)\""
            }
            .joined(separator: csvSeparator)
    }

    static func decodeCSV(_ csv: String) -> [String] {
        guard csv.isEmpty == false else { return [] }

        var results: [String] = []
        var current = ""
        var isInsideQuotes = false
        let characters = Array(csv)
        var index = 0

        while index < characters.count {
            let character = characters[index]

            if character == "\"" {
                let nextIndex = index + 1
                if isInsideQuotes && nextIndex < characters.count && characters[nextIndex] == "\"" {
                    current.append("\"")
                    index += 1
                } else {
                    isInsideQuotes.toggle()
                }
            } else if character == Character(csvSeparator) && isInsideQuotes == false {
                results.append(current)
                current = ""
            } else {
                current.append(character)
            }

            index += 1
        }

        results.append(current)
        return results
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
    }
}
