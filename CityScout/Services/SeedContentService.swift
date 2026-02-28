import Foundation
import SwiftData

enum SeedContentService {
    static func upsertBarcelonaSeed(in modelContext: ModelContext) throws {
        try upsertSeed(named: "barcelona_seed_v1", in: modelContext)
    }

    static func upsertSeed(named seedName: String, in modelContext: ModelContext) throws {
        try SeedContentImporter.importIfNeeded(modelContext: modelContext, seedName: seedName)
    }

}

enum SeedContentError: LocalizedError {
    case missingSeedFile(String)

    var errorDescription: String? {
        switch self {
        case .missingSeedFile(let seedName):
            return "Could not find \(seedName).json in app bundle resources."
        }
    }
}

struct SeedContentDTO: Decodable {
    let destination: String
    let languages: [String]
    let situations: [SituationDTO]
}

struct SituationDTO: Decodable {
    let title: String
    let phrases: [PhraseDTO]
}

struct PhraseDTO: Decodable {
    let targetText: String
    let englishMeaning: String
    let notes: String?
    let tags: [String]

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
