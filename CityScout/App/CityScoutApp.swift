//
//  CityScoutApp.swift
//  CityScout
//
//  Created by Tim Finch on 15/02/2026.
//

import SwiftUI
import SwiftData

@main
struct CityScoutApp: App {
    /// SwiftData container used across the app.
    ///
    /// Note: during development, SwiftData can fail to open an existing on-disk store
    /// if the model schema has changed without a migration plan. Rather than crashing
    /// the entire app, we fall back to an in-memory store (data will not persist).
    ///
    /// If you hit this often, either:
    /// - delete the app from the Simulator / device (wipes the store), or
    /// - bump the `storeFilename` below to create a fresh store.
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Trip.self,
            Situation.self,
            Phrase.self,
            SavedPhrase.self,
            SavedPlace.self,
            SavedItinerary.self,
        ])

        // Use the default on-disk SwiftData store.
        // If the schema changes during development and SwiftData can't open the store,
        // delete the app from the Simulator/device to wipe the store.
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Development-friendly fallback so the app can still run.
            // (In-memory means nothing is persisted between launches.)
            let inMemoryConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            do {
                return try ModelContainer(for: schema, configurations: [inMemoryConfig])
            } catch {
                fatalError("Could not create ModelContainer (disk + in-memory failed): \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
