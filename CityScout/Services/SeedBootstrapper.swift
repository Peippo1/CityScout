import Foundation
import SwiftData

enum SeedBootstrapper {
    private static let hasSeededKey = "hasSeeded_v1"

    @MainActor
    static func runIfNeeded(
        in modelContext: ModelContext,
        defaults: UserDefaults = .standard
    ) throws {
        let seeds: [(name: String, key: String)] = [
            ("barcelona_seed_v1", "didImportSeed_barcelona_seed_v1"),
            ("paris_seed_v1", "didImportSeed_paris_seed_v1"),
            ("athens_seed_v1", "didImportSeed_athens_seed_v1"),
            ("rome_seed_v1", "didImportSeed_rome_seed_v1"),
            ("helsinki_seed_v1", "didImportSeed_helsinki_seed_v1"),
            ("copenhagen_seed_v1", "didImportSeed_copenhagen_seed_v1"),
            ("lisbon_seed_v1", "didImportSeed_lisbon_seed_v1")
        ]

        let tripCount = try modelContext.fetchCount(FetchDescriptor<Trip>())
        if tripCount > 0 {
            defaults.set(true, forKey: hasSeededKey)
            debugLog("SeedBootstrapper.runIfNeeded skipped: trips already exist (\(tripCount))")
            return
        }

        debugLog("SeedBootstrapper.runIfNeeded starting")
        var failedSeeds: [String] = []
        for seed in seeds {
            do {
                try SeedContentService.upsertSeed(named: seed.name, in: modelContext)
                defaults.set(true, forKey: seed.key)
                debugLog("Seed '\(seed.name)' imported and key '\(seed.key)' persisted")
            } catch {
                failedSeeds.append(seed.name)
                print("Seed import failed for \(seed.name): \(error.localizedDescription)")
            }
        }

        let postImportTripCount = try modelContext.fetchCount(FetchDescriptor<Trip>())
        if postImportTripCount > 0 {
            defaults.set(true, forKey: hasSeededKey)
        }

        debugLog("SeedBootstrapper.runIfNeeded finished with \(postImportTripCount) trips")
        if failedSeeds.isEmpty == false {
            throw SeedBootstrapperError.failedSeeds(failedSeeds)
        }
    }
}

enum SeedBootstrapperError: LocalizedError {
    case failedSeeds([String])

    var errorDescription: String? {
        switch self {
        case .failedSeeds(let names):
            return "Failed to import some seed packs: \(names.joined(separator: ", "))"
        }
    }
}
