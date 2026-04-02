import XCTest
import SwiftData
@testable import CityScout

final class CityScoutTests: XCTestCase {
    func testPlannerConfigurationUsesUniversalBaseURLForHostedEnvironment() {
        let configuration = AppEnvironment.resolvePlannerConfiguration(
            infoDictionary: [
                "CITYSCOUT_API_BASE_URL": "https://staging.cityscout.example",
                "CITYSCOUT_SIMULATOR_API_BASE_URL": "http://127.0.0.1:8000",
                "CITYSCOUT_DEVICE_API_BASE_URL": "http://192.168.1.10:8000",
                "CITYSCOUT_APP_SHARED_SECRET": "beta-secret"
            ],
            environment: [:],
            isSimulator: false,
            isDebugBuild: false
        )

        XCTAssertEqual(configuration.baseURLString, "https://staging.cityscout.example")
        XCTAssertEqual(configuration.baseURLSource, "CITYSCOUT_API_BASE_URL")
        XCTAssertEqual(configuration.appSharedSecret, "beta-secret")
    }

    func testPlannerConfigurationFallsBackToSimulatorLocalhostOnlyInDebug() {
        let configuration = AppEnvironment.resolvePlannerConfiguration(
            infoDictionary: [:],
            environment: [:],
            isSimulator: true,
            isDebugBuild: true
        )

        XCTAssertEqual(configuration.baseURLString, "http://127.0.0.1:8000")
        XCTAssertEqual(configuration.baseURLSource, "simulator fallback")
        XCTAssertTrue(configuration.appSharedSecret.isEmpty)
    }

    func testPlannerConfigurationRequiresExplicitDeviceURLOutsideSimulatorFallback() {
        let configuration = AppEnvironment.resolvePlannerConfiguration(
            infoDictionary: [:],
            environment: [:],
            isSimulator: false,
            isDebugBuild: true
        )

        XCTAssertEqual(configuration.baseURLString, "")
        XCTAssertEqual(configuration.baseURLSource, "unconfigured")
    }

    func testOrderedUniqueActivityNamesPreservesFirstTrimmedValue() {
        let activities = [
            "  Louvre Museum  ",
            "Cafe de Flore",
            "louvre   museum",
            "  ",
            "Cafe   de   Flore"
        ]

        let uniqueActivities = PlanSavedPlaceSupport.orderedUniqueActivityNames(from: activities)

        XCTAssertEqual(uniqueActivities, ["Louvre Museum", "Cafe de Flore"])
    }

    func testResolvedActivityNameUsesMatchedPOIName() {
        let resolvedName = PlanSavedPlaceSupport.resolvedActivityName(
            for: "Coffee near the Louvre",
            resolveSavedPlace: { _ in
                ResolvedItineraryPlace(
                    name: "Louvre Museum",
                    category: .sights,
                    latitude: 48.8606,
                    longitude: 2.3376
                )
            }
        )

        XCTAssertEqual(resolvedName, "louvre museum")
    }

    func testSavedPlaceNamesForRequestDeduplicatesAndKeepsNewestFirst() {
        let olderPlace = SavedPlace(
            name: "Louvre Museum",
            category: .sights,
            source: SavedPlace.Source.itinerary.rawValue,
            destinationName: "Paris",
            latitude: 48.8606,
            longitude: 2.3376,
            createdAt: Date(timeIntervalSince1970: 100)
        )
        let newerDuplicate = SavedPlace(
            name: "  Louvre   Museum  ",
            category: .sights,
            source: SavedPlace.Source.manual.rawValue,
            destinationName: "Paris",
            latitude: 48.8606,
            longitude: 2.3376,
            createdAt: Date(timeIntervalSince1970: 200)
        )
        let newestUnique = SavedPlace(
            name: "Cafe de Flore",
            category: .cafes,
            source: SavedPlace.Source.manual.rawValue,
            destinationName: "Paris",
            latitude: 48.8546,
            longitude: 2.3339,
            createdAt: Date(timeIntervalSince1970: 300)
        )

        let requestNames = PlanSavedPlaceSupport.savedPlaceNamesForRequest(
            from: [olderPlace, newestUnique, newerDuplicate]
        )

        XCTAssertEqual(requestNames, ["Cafe de Flore", "Louvre   Museum"])
    }

    @MainActor
    func testSeedImportIsIdempotentForBarcelonaAndParis() throws {
        let container = try makeInMemoryContainer()
        let modelContext = ModelContext(container)
        let seeds = ["barcelona_seed_v1", "paris_seed_v1"]

        for seed in seeds {
            try SeedContentService.upsertSeed(named: seed, in: modelContext)
        }

        let trips = try fetchTrips(in: modelContext)
        XCTAssertEqual(trips.count, 2, "Expected exactly two trips after first import.")

        let destinationNames = Set(trips.map(\.destinationName))
        XCTAssertEqual(destinationNames, Set(["Barcelona", "Paris"]), "Unexpected trip destinations after seed import.")

        for trip in trips {
            let situations = try fetchSituations(for: trip, in: modelContext)
            XCTAssertGreaterThan(situations.count, 0, "Each trip should contain at least one situation.")

            let titles = situations.map(\.title)
            XCTAssertEqual(Set(titles).count, titles.count, "Situation titles must be unique within a trip.")

            for situation in situations {
                let phrases = try fetchPhrases(for: situation, in: modelContext)
                XCTAssertGreaterThan(phrases.count, 0, "Each situation should contain at least one phrase.")

                let targetTexts = phrases.map(\.targetText)
                XCTAssertEqual(
                    Set(targetTexts).count,
                    targetTexts.count,
                    "Phrase targetText values must be unique within a situation."
                )
            }
        }

        let firstTripCount = try count(Trip.self, in: modelContext)
        let firstSituationCount = try count(Situation.self, in: modelContext)
        let firstPhraseCount = try count(Phrase.self, in: modelContext)

        for seed in seeds {
            try SeedContentService.upsertSeed(named: seed, in: modelContext)
        }

        let secondTripCount = try count(Trip.self, in: modelContext)
        let secondSituationCount = try count(Situation.self, in: modelContext)
        let secondPhraseCount = try count(Phrase.self, in: modelContext)

        XCTAssertEqual(firstTripCount, seeds.count, "Trip count should match number of imported seeds.")
        XCTAssertEqual(secondTripCount, firstTripCount, "Trip count should not increase on re-import.")
        XCTAssertEqual(secondSituationCount, firstSituationCount, "Situation count should remain stable on re-import.")
        XCTAssertEqual(secondPhraseCount, firstPhraseCount, "Phrase count should remain stable on re-import.")
        XCTAssertGreaterThan(firstSituationCount, 0, "Situations should be imported from seed content.")
        XCTAssertGreaterThan(firstPhraseCount, 0, "Phrases should be imported from seed content.")
    }

    @MainActor
    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([Trip.self, Situation.self, Phrase.self, SavedPhrase.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    @MainActor
    private func count<T: PersistentModel>(_ model: T.Type, in modelContext: ModelContext) throws -> Int {
        try modelContext.fetchCount(FetchDescriptor<T>())
    }

    @MainActor
    private func fetchTrips(in modelContext: ModelContext) throws -> [Trip] {
        try modelContext.fetch(FetchDescriptor<Trip>())
    }

    @MainActor
    private func fetchSituations(for trip: Trip, in modelContext: ModelContext) throws -> [Situation] {
        let tripID = trip.id
        let descriptor = FetchDescriptor<Situation>(
            predicate: #Predicate { situation in
                situation.trip.id == tripID
            }
        )
        return try modelContext.fetch(descriptor)
    }

    @MainActor
    private func fetchPhrases(for situation: Situation, in modelContext: ModelContext) throws -> [Phrase] {
        let situationID = situation.id
        let descriptor = FetchDescriptor<Phrase>(
            predicate: #Predicate { phrase in
                phrase.situation.id == situationID
            }
        )
        return try modelContext.fetch(descriptor)
    }
}
