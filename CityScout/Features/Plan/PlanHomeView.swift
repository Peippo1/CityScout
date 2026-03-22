import SwiftData
import SwiftUI
import UIKit

private enum PlanPreference: String, CaseIterable, Identifiable {
    case relaxed
    case foodFocused
    case sightseeing
    case cafes
    case nightOut

    var id: String { rawValue }

    var title: String {
        switch self {
        case .relaxed:
            return "Relaxed"
        case .foodFocused:
            return "Food-focused"
        case .sightseeing:
            return "Sightseeing"
        case .cafes:
            return "Cafés"
        case .nightOut:
            return "Night Out"
        }
    }

    var icon: String {
        switch self {
        case .relaxed:
            return "leaf.fill"
        case .foodFocused:
            return "fork.knife"
        case .sightseeing:
            return "binoculars.fill"
        case .cafes:
            return "cup.and.saucer.fill"
        case .nightOut:
            return "moon.stars.fill"
        }
    }

}

private struct PlanSection: Identifiable {
    let title: String
    let activities: [String]

    var id: String { title }
}

struct PlanHomeView: View {
    let destinationName: String

    @Environment(\.modelContext) private var modelContext

    private let preferenceColumns = [
        GridItem(.adaptive(minimum: 140), spacing: 10, alignment: .leading)
    ]

    @State private var prompt = ""
    @State private var selectedPreferences: Set<PlanPreference> = []
    @State private var itinerary: PlanAPIService.ItineraryResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var savedActivityNames: Set<String> = []

    private let planAPIService = PlanAPIService()

    private var trimmedPrompt: String {
        prompt.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canGenerate: Bool {
        trimmedPrompt.isEmpty == false || selectedPreferences.isEmpty == false
    }

    private var itinerarySections: [PlanSection] {
        guard let itinerary else { return [] }
        return [
            PlanSection(title: itinerary.morning.title, activities: itinerary.morning.activities),
            PlanSection(title: itinerary.afternoon.title, activities: itinerary.afternoon.activities),
            PlanSection(title: itinerary.evening.title, activities: itinerary.evening.activities),
        ]
    }

    private var allItineraryActivities: [String] {
        var uniqueActivities: [String] = []

        for activity in itinerarySections.flatMap(\.activities).map(normalizedActivityName) {
            guard activity.isEmpty == false, uniqueActivities.contains(activity) == false else {
                continue
            }
            uniqueActivities.append(activity)
        }

        return uniqueActivities
    }

    private var isEntireItinerarySaved: Bool {
        allItineraryActivities.isEmpty == false
        && allItineraryActivities.allSatisfy { savedActivityNames.contains($0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                CityHeaderView(destinationName: destinationName)
                    .padding(.horizontal)
                    .padding(.top, 8)

                introCard
                promptCard
                preferencesSection
                actionSection

                if let errorMessage {
                    errorCard(message: errorMessage)
                }

                if itinerarySections.isEmpty == false {
                    itinerarySection
                }
            }
            .padding(.bottom)
        }
        .navigationTitle("\(destinationName) Plan")
        .task {
            await loadSavedActivities()
        }
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Plan Your Day")
                .font(.title2.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)

            Text("Generate a simple itinerary for your time in \(destinationName).")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
    }

    private var promptCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What do you want from the day?")
                .font(.headline)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))

                if trimmedPrompt.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Plan me a relaxed day in Paris")
                        Text("I want coffee, art, and a nice dinner in Rome")
                        Text("Give me a food-focused day in Athens")
                    }
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                    .allowsHitTesting(false)
                }

                TextEditor(text: $prompt)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 140)
                    .padding(12)
                    .accessibilityLabel("Day plan request")
                    .accessibilityHint("Describe how you want to spend your day in the city.")
            }
        }
        .padding(.horizontal)
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Preferences")
                .font(.headline)

            LazyVGrid(columns: preferenceColumns, alignment: .leading, spacing: 10) {
                ForEach(PlanPreference.allCases) { preference in
                    preferenceChip(for: preference)
                }
            }
        }
        .padding(.horizontal)
    }

    private func preferenceChip(for preference: PlanPreference) -> some View {
        let isSelected = selectedPreferences.contains(preference)

        return Button {
            if isSelected {
                selectedPreferences.remove(preference)
            } else {
                selectedPreferences.insert(preference)
            }
        } label: {
            Label(preference.title, systemImage: preference.icon)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                )
                .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(preference.title)
        .accessibilityHint("Adds this preference to your itinerary request.")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }

    private var actionSection: some View {
        Button {
            Task {
                await generateItinerary()
            }
        } label: {
            HStack {
                if isLoading {
                    ProgressView()
                        .accessibilityHidden(true)
                }

                Text(isLoading ? "Generating..." : "Generate Itinerary")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(canGenerate == false || isLoading)
        .padding(.horizontal)
        .accessibilityLabel("Generate itinerary")
        .accessibilityHint("Generates a day plan using your prompt and selected preferences.")
    }

    private var itinerarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Text("Suggested Plan")
                    .font(.headline)

                Spacer()

                Button {
                    saveAllActivities()
                } label: {
                    Label(isEntireItinerarySaved ? "Saved" : "Save All", systemImage: isEntireItinerarySaved ? "bookmark.fill" : "bookmark")
                        .font(.subheadline.weight(.semibold))
                        .labelStyle(.titleAndIcon)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(
                                    isEntireItinerarySaved
                                    ? Color.accentColor.opacity(0.18)
                                    : Color(.tertiarySystemBackground)
                                )
                        )
                        .foregroundStyle(isEntireItinerarySaved ? Color.accentColor : Color.primary)
                        .opacity((isEntireItinerarySaved || isLoading) ? 0.85 : 1)
                        .animation(.easeInOut(duration: 0.2), value: isEntireItinerarySaved)
                }
                .buttonStyle(.plain)
                .disabled(isLoading || isEntireItinerarySaved)
                .accessibilityLabel("Save all itinerary activities")
                .accessibilityHint("Adds all activities in this itinerary to saved places")
                .accessibilityValue(isEntireItinerarySaved ? "Saved" : "Not saved")
            }
            .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(itinerarySections) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.title)
                            .font(.headline)
                            .fixedSize(horizontal: false, vertical: true)

                        ForEach(section.activities, id: \.self) { activity in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 7))
                                    .padding(.top, 6)
                                    .foregroundStyle(Color.accentColor)
                                    .accessibilityHidden(true)

                                Text(activity)
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)

                                Spacer(minLength: 12)

                                saveActivityButton(for: activity)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .accessibilityElement(children: .contain)
                }
            }
            .padding(.horizontal)

            if let notes = itinerary?.notes, notes.isEmpty == false {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)

                    ForEach(notes, id: \.self) { note in
                        Text(note)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
                .padding(.horizontal)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func errorCard(message: String) -> some View {
        Text(message)
            .font(.footnote)
            .foregroundStyle(.red)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal)
            .accessibilityLabel("Planner error. \(message)")
    }

    private func saveActivityButton(for activity: String) -> some View {
        let isSaved = savedActivityNames.contains(normalizedActivityName(activity))

        return Button {
            saveActivity(activity)
        } label: {
            Label(isSaved ? "Saved" : "Save", systemImage: isSaved ? "bookmark.fill" : "bookmark")
                .font(.caption.weight(.semibold))
                .labelStyle(.titleAndIcon)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSaved ? Color.accentColor.opacity(0.18) : Color(.tertiarySystemBackground))
                )
                .foregroundStyle(isSaved ? Color.accentColor : Color.primary)
                .opacity(isSaved ? 0.85 : 1)
                .animation(.easeInOut(duration: 0.2), value: isSaved)
        }
        .buttonStyle(.plain)
        .disabled(isSaved)
        .accessibilityLabel(isSaved ? "Activity saved" : "Save activity")
        .accessibilityHint(isSaved ? "This activity is already in your saved places." : "Adds this activity to your saved places")
        .accessibilityValue(isSaved ? "Saved" : "Not saved")
    }

    @MainActor
    private func loadSavedActivities() async {
        let destination = destinationName

        do {
            let descriptor = FetchDescriptor<SavedPlace>(
                predicate: #Predicate<SavedPlace> { place in
                    place.destinationName == destination
                }
            )
            let savedPlaces = try modelContext.fetch(descriptor)
            savedActivityNames = Set(savedPlaces.map(\.name).map(normalizedActivityName))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveActivity(_ activity: String) {
        let trimmedActivity = normalizedActivityName(activity)

        guard savedActivityNames.contains(trimmedActivity) == false else {
            return
        }

        do {
            let destination = destinationName
            let descriptor = FetchDescriptor<SavedPlace>(
                predicate: #Predicate<SavedPlace> { place in
                    place.name == trimmedActivity && place.destinationName == destination
                }
            )

            let existingPlace = try modelContext.fetch(descriptor).first
            guard existingPlace == nil else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    savedActivityNames.insert(trimmedActivity)
                }
                return
            }

            try SavedPlaceService.savePlace(
                name: trimmedActivity,
                destinationName: destinationName,
                latitude: 0,
                longitude: 0,
                in: modelContext
            )

            withAnimation(.easeInOut(duration: 0.2)) {
                savedActivityNames.insert(trimmedActivity)
            }

            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveAllActivities() {
        let activitiesToSave = allItineraryActivities

        guard activitiesToSave.isEmpty == false else {
            return
        }

        do {
            let destination = destinationName
            let descriptor = FetchDescriptor<SavedPlace>(
                predicate: #Predicate<SavedPlace> { place in
                    place.destinationName == destination
                }
            )

            let existingPlaces = try modelContext.fetch(descriptor)
            var knownSavedNames = Set(existingPlaces.map(\.name).map(normalizedActivityName))
            var didInsertNewPlace = false

            for activity in activitiesToSave where knownSavedNames.contains(activity) == false {
                try SavedPlaceService.savePlace(
                    name: activity,
                    destinationName: destinationName,
                    latitude: 0,
                    longitude: 0,
                    in: modelContext
                )
                knownSavedNames.insert(activity)
                didInsertNewPlace = true
            }

            withAnimation(.easeInOut(duration: 0.2)) {
                savedActivityNames.formUnion(activitiesToSave)
            }

            if didInsertNewPlace {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func normalizedActivityName(_ activity: String) -> String {
        activity.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @MainActor
    private func generateItinerary() async {
        isLoading = true
        errorMessage = nil

        do {
            itinerary = try await planAPIService.generateItinerary(
                destination: destinationName,
                prompt: trimmedPrompt,
                preferences: selectedPreferences
                    .sorted { $0.title < $1.title }
                    .map(\.title),
                savedPlaces: []
            )
            await loadSavedActivities()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        PlanHomeView(destinationName: "Paris")
    }
}
