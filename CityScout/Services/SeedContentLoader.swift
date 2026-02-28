import Foundation

enum SeedContentLoader {
    static func loadTrip(seedName: String, bundle: Bundle = .main) throws -> SeedTripDTO {
        let urlCandidates = [
            bundle.url(forResource: seedName, withExtension: "json"),
            bundle.url(forResource: seedName, withExtension: "json", subdirectory: "SeedContent"),
            bundle.url(forResource: seedName, withExtension: "json", subdirectory: "Resources/SeedContent")
        ]

        guard let fileURL = urlCandidates.compactMap({ $0 }).first else {
            throw SeedContentLoaderError.fileNotFound(seedName: seedName)
        }

        do {
            let data = try Data(contentsOf: fileURL)
            do {
                return try JSONDecoder().decode(SeedTripDTO.self, from: data)
            } catch {
                throw SeedContentLoaderError.decodingFailed(seedName: seedName, underlying: error)
            }
        } catch {
            throw SeedContentLoaderError.readFailed(seedName: seedName, underlying: error)
        }
    }
}

enum SeedContentLoaderError: LocalizedError {
    case fileNotFound(seedName: String)
    case readFailed(seedName: String, underlying: Error)
    case decodingFailed(seedName: String, underlying: Error)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let seedName):
            return "Seed file '\(seedName).json' was not found in the app bundle."
        case .readFailed(let seedName, let underlying):
            return "Failed to read seed file '\(seedName).json': \(underlying.localizedDescription)"
        case .decodingFailed(let seedName, let underlying):
            return "Failed to decode seed file '\(seedName).json' into SeedTripDTO: \(underlying.localizedDescription)"
        }
    }
}
