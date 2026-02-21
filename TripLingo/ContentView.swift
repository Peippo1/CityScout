//
//  ContentView.swift
//  TripLingo
//
//  Created by Tim Finch on 15/02/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var didRunSeed = false
    private let barcelonaSeedKey = "didImportSeed_barcelona_seed_v1"

    var body: some View {
        TabView {
            NavigationStack {
                LessonsHomeView()
            }
            .tabItem {
                Label("Lessons", systemImage: "book")
            }

            NavigationStack {
                PhrasebookHomeView()
            }
            .tabItem {
                Label("Phrasebook", systemImage: "text.book.closed")
            }

            NavigationStack {
                TranslateHomeView()
            }
            .tabItem {
                Label("Translate", systemImage: "globe")
            }

            NavigationStack {
                ExploreHomeView()
            }
            .tabItem {
                Label("Explore", systemImage: "map")
            }
        }
        .task {
            guard !didRunSeed else { return }
            didRunSeed = true
            let defaults = UserDefaults.standard
            if defaults.bool(forKey: barcelonaSeedKey) { return }

            do {
                try SeedContentService.upsertBarcelonaSeed(in: modelContext)
                defaults.set(true, forKey: barcelonaSeedKey)
            } catch {
                assertionFailure("Seed failed: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    ContentView()
}
