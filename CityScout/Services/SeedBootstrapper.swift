import Foundation
import SwiftData

enum SeedBootstrapper {
    private static var didRunThisLaunch = false

    @MainActor
    static func run(in modelContext: ModelContext) {
        guard didRunThisLaunch == false else {
            debugLog("SeedBootstrapper.run skipped: already ran this app launch")
            return
        }
        didRunThisLaunch = true

        let seeds: [(name: String, key: String)] = [
            ("barcelona_seed_v1", "didImportSeed_barcelona_seed_v1"),
            ("paris_seed_v1", "didImportSeed_paris_seed_v1")
        ]

        let defaults = UserDefaults.standard

        debugLog("SeedBootstrapper.run starting")
        for seed in seeds {
            if defaults.bool(forKey: seed.key) {
                debugLog("Seed '\(seed.name)' already imported for key '\(seed.key)'")
                continue
            }
            do {
                try SeedContentService.upsertSeed(named: seed.name, in: modelContext)
                defaults.set(true, forKey: seed.key)
                debugLog("Seed '\(seed.name)' imported and key '\(seed.key)' persisted")
            } catch {
                debugLog("Seed import failed for \(seed.name): \(error.localizedDescription)")
                assertionFailure("Seed import failed for \(seed.name): \(error.localizedDescription)")
            }
        }
        debugLog("SeedBootstrapper.run finished")
    }
}
