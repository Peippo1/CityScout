import Foundation

struct SeedTripDTO: Codable {
    let destination: String
    let languages: [String]
    let situations: [SeedSituationDTO]
}

struct SeedSituationDTO: Codable {
    let title: String
    let phrases: [SeedPhraseDTO]
}

struct SeedPhraseDTO: Codable {
    let targetText: String
    let englishMeaning: String
    let notes: String?
    let tags: [String]

    init(
        targetText: String,
        englishMeaning: String,
        notes: String?,
        tags: [String] = []
    ) {
        self.targetText = targetText
        self.englishMeaning = englishMeaning
        self.notes = notes
        self.tags = tags
    }

    private enum CodingKeys: String, CodingKey {
        case targetText
        case englishMeaning
        case notes
        case tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        targetText = try container.decode(String.self, forKey: .targetText)
        englishMeaning = try container.decode(String.self, forKey: .englishMeaning)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
    }
}
