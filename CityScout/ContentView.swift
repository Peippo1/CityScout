//
//  ContentView.swift
//  CityScout
//
//  Created by Tim Finch on 15/02/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("selectedDestinationName") private var selectedDestinationName = ""
    @AppStorage("seedErrorMessage") private var seedErrorMessage = ""
    @State private var didRunSeed = false

    var body: some View {
        Group {
            if hasSeenOnboarding == false {
                OnboardingFlowView()
            } else if selectedDestinationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                NavigationStack {
                    DestinationPickerView()
                }
            } else {
                TripShellView(destinationName: selectedDestinationName)
            }
        }
        .task {
            guard !didRunSeed else { return }
            didRunSeed = true
            await MainActor.run {
                do {
                    // Seed from the injected modelContext so seeding and UI queries use the same container.
                    try SeedBootstrapper.runIfNeeded(in: modelContext)
                    seedErrorMessage = ""
                } catch {
                    print("Seed bootstrap failed: \(error.localizedDescription)")
                    seedErrorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
