import Foundation
import SwiftData

enum SeedBootstrapper {
    static func run(in modelContext: ModelContext) {
        let seeds: [(name: String, key: String)] = [
            ("barcelona_seed_v1", "didImportSeed_barcelona_seed_v1"),
            ("paris_seed_v1", "didImportSeed_paris_seed_v1")
        ]

        let defaults = UserDefaults.standard

        for seed in seeds {
            if defaults.bool(forKey: seed.key) { continue }
            do {
                try SeedContentService.upsertSeed(named: seed.name, in: modelContext)
                defaults.set(true, forKey: seed.key)
            } catch {
                assertionFailure("Seed import failed for \(seed.name): \(error.localizedDescription)")
            }
        }
    }
}
