import SwiftData
import SwiftUI

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

enum PlanSavedPlaceSupport {
    static func normalizedActivityName(_ activity: String) -> String {
        let collapsedWhitespace = activity
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.isEmpty == false }
            .joined(separator: " ")

        return collapsedWhitespace.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )
    }

    static func resolvedActivityName(
        for activity: String,
        resolveSavedPlace: (String) -> ResolvedItineraryPlace
    ) -> String {
        let resolvedName = resolveSavedPlace(activity).name
        let normalizedResolvedName = normalizedActivityName(resolvedName)

        if normalizedResolvedName.isEmpty == false {
            return normalizedResolvedName
        }

        return normalizedActivityName(activity)
    }

    static func savedPlaceNamesForRequest(
        from savedPlaces: [SavedPlace],
        limit: Int = 25
    ) -> [String] {
        guard limit > 0 else { return [] }

        var seenNames: Set<String> = []
        var orderedNames: [String] = []

        for place in savedPlaces.sorted(by: { $0.createdAt > $1.createdAt }) {
            let normalizedName = normalizedActivityName(place.name)
            guard normalizedName.isEmpty == false else { continue }
            guard seenNames.insert(normalizedName).inserted else { continue }

            orderedNames.append(place.name.trimmingCharacters(in: .whitespacesAndNewlines))
            if orderedNames.count == limit {
                break
            }
        }

        return orderedNames
    }
}

private struct PlanPersistenceCoordinator {
    let modelContext: ModelContext
    let destinationName: String
    let normalizeActivityName: (String) -> String
    let resolveSavedPlace: (String) -> ResolvedItineraryPlace

    func loadSavedActivityNames() throws -> Set<String> {
        let destination = destinationName
        let descriptor = FetchDescriptor<SavedPlace>(
            predicate: #Predicate<SavedPlace> { place in
                place.destinationName == destination
            }
        )
        let savedPlaces = try modelContext.fetch(descriptor)
        return Set(savedPlaces.map(\.name).map(normalizeActivityName))
    }

    @discardableResult
    func saveActivityIfNeeded(_ activity: String) throws -> String? {
        let normalizedActivity = resolvedActivityName(for: activity)
        guard normalizedActivity.isEmpty == false else {
            return nil
        }

        let existingPlaces = try fetchSavedPlacesForDestination()
        _ = try persistResolvedPlaceIfNeeded(for: activity, existingPlaces: existingPlaces)
        return normalizedActivity
    }

    func saveAllActivitiesIfNeeded(_ activities: [String]) throws -> Set<String> {
        guard activities.isEmpty == false else {
            return []
        }

        var existingPlaces = try fetchSavedPlacesForDestination()
        var savedNames: Set<String> = []

        for activity in activities {
            let normalizedActivity = resolvedActivityName(for: activity)
            guard normalizedActivity.isEmpty == false else { continue }

            if let savedPlace = try persistResolvedPlaceIfNeeded(for: activity, existingPlaces: existingPlaces) {
                existingPlaces.append(savedPlace)
            }

            savedNames.insert(normalizedActivity)
        }

        return savedNames
    }

    func savedPlaceNamesForRequest() throws -> [String] {
        PlanSavedPlaceSupport.savedPlaceNamesForRequest(
            from: try fetchSavedPlacesForDestination()
        )
    }

    func saveCurrentItinerary(
        itinerary: PlanAPIService.ItineraryResponse,
        prompt: String,
        selectedPreferences: Set<PlanPreference>
    ) throws -> SavedItinerary {
        let savedItinerary = SavedItinerary(
            destinationName: destinationName,
            prompt: prompt,
            preferencesCSV: SavedItinerary.encodeCSV(selectedPreferences.map(\.rawValue).sorted()),
            morningTitle: itinerary.morning.title,
            morningActivitiesCSV: SavedItinerary.encodeCSV(itinerary.morning.activities),
            afternoonTitle: itinerary.afternoon.title,
            afternoonActivitiesCSV: SavedItinerary.encodeCSV(itinerary.afternoon.activities),
            eveningTitle: itinerary.evening.title,
            eveningActivitiesCSV: SavedItinerary.encodeCSV(itinerary.evening.activities),
            notesCSV: SavedItinerary.encodeCSV(itinerary.notes)
        )

        modelContext.insert(savedItinerary)
        try modelContext.save()
        return savedItinerary
    }

    func deleteSavedItinerary(_ savedItinerary: SavedItinerary) throws -> String {
        let deletedSignature = signature(for: savedItinerary)
        modelContext.delete(savedItinerary)
        try modelContext.save()
        return deletedSignature
    }

    func signature(for savedItinerary: SavedItinerary) -> String {
        [
            savedItinerary.destinationName,
            savedItinerary.prompt.trimmingCharacters(in: .whitespacesAndNewlines),
            savedItinerary.preferences.sorted().joined(separator: "|"),
            savedItinerary.morningTitle,
            savedItinerary.morningActivities.joined(separator: "|"),
            savedItinerary.afternoonTitle,
            savedItinerary.afternoonActivities.joined(separator: "|"),
            savedItinerary.eveningTitle,
            savedItinerary.eveningActivities.joined(separator: "|"),
            savedItinerary.notes.joined(separator: "|")
        ]
        .joined(separator: "||")
    }

    private func fetchSavedPlacesForDestination() throws -> [SavedPlace] {
        let destination = destinationName
        let descriptor = FetchDescriptor<SavedPlace>(
            predicate: #Predicate<SavedPlace> { place in
                place.destinationName == destination
            }
        )
        return try modelContext.fetch(descriptor)
    }

    @discardableResult
    private func persistResolvedPlaceIfNeeded(
        for activity: String,
        existingPlaces: [SavedPlace]
    ) throws -> SavedPlace? {
        let normalizedActivity = normalizeActivityName(activity)
        guard normalizedActivity.isEmpty == false else {
            return nil
        }

        let resolvedPlace = resolveSavedPlace(activity)
        let normalizedResolvedName = normalizeActivityName(resolvedPlace.name)

        guard existingPlaces.contains(where: { existingPlace in
            normalizeActivityName(existingPlace.name) == normalizedResolvedName
        }) == false else {
            return nil
        }

        let savedPlace = SavedPlace(
            name: resolvedPlace.name,
            category: resolvedPlace.category,
            source: SavedPlace.Source.itinerary.rawValue,
            destinationName: destinationName,
            latitude: resolvedPlace.latitude,
            longitude: resolvedPlace.longitude
        )
        modelContext.insert(savedPlace)
        try modelContext.save()
        return savedPlace
    }

    private func resolvedActivityName(for activity: String) -> String {
        PlanSavedPlaceSupport.resolvedActivityName(
            for: activity,
            resolveSavedPlace: resolveSavedPlace
        )
    }
}

struct PlanHomeView: View {
    let destinationName: String

    @Environment(\.modelContext) private var modelContext
    @Query private var savedItineraries: [SavedItinerary]

    private let preferenceColumns = [
        GridItem(.adaptive(minimum: 140), spacing: 10, alignment: .leading)
    ]

    @State private var prompt = ""
    @State private var selectedPreferences: Set<PlanPreference> = []
    @State private var itinerary: PlanAPIService.ItineraryResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var savedActivityNames: Set<String> = []
    @State private var persistedItinerarySignature: String?

    private let planAPIService = PlanAPIService()

    init(destinationName: String) {
        self.destinationName = destinationName
        _savedItineraries = Query(
            filter: #Predicate { itinerary in
                itinerary.destinationName == destinationName
            },
            sort: [SortDescriptor(\SavedItinerary.createdAt, order: .reverse)]
        )
    }

    private var persistenceCoordinator: PlanPersistenceCoordinator {
        PlanPersistenceCoordinator(
            modelContext: modelContext,
            destinationName: destinationName,
            normalizeActivityName: normalizedActivityName,
            resolveSavedPlace: resolvedSavedPlace
        )
    }

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

        for activity in itinerarySections.flatMap(\.activities) {
            guard activity.isEmpty == false, uniqueActivities.contains(activity) == false else {
                continue
            }
            uniqueActivities.append(activity)
        }

        return uniqueActivities
    }

    private var allItineraryActivityIdentifiers: [String] {
        var uniqueActivities: [String] = []

        for activity in allItineraryActivities.map(savedActivityIdentifier) {
            guard activity.isEmpty == false, uniqueActivities.contains(activity) == false else {
                continue
            }
            uniqueActivities.append(activity)
        }

        return uniqueActivities
    }

    private var isEntireItinerarySaved: Bool {
        allItineraryActivityIdentifiers.isEmpty == false
        && allItineraryActivityIdentifiers.allSatisfy { savedActivityNames.contains($0) }
    }

    private var currentItinerarySignature: String? {
        guard let itinerary else { return nil }

        return [
            destinationName,
            trimmedPrompt,
            selectedPreferences.map(\.rawValue).sorted().joined(separator: "|"),
            itinerary.morning.title,
            itinerary.morning.activities.joined(separator: "|"),
            itinerary.afternoon.title,
            itinerary.afternoon.activities.joined(separator: "|"),
            itinerary.evening.title,
            itinerary.evening.activities.joined(separator: "|"),
            itinerary.notes.joined(separator: "|")
        ]
        .joined(separator: "||")
    }

    private var isCurrentItineraryPersisted: Bool {
        guard let currentItinerarySignature else { return false }
        return persistedItinerarySignature == currentItinerarySignature
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
                debugBackendSection

                if let errorMessage {
                    errorCard(message: errorMessage)
                }

                if itinerarySections.isEmpty == false {
                    itinerarySection
                }

                savedItinerariesSection
            }
            .padding(.bottom)
        }
        .background(Color.brandCream.ignoresSafeArea())
        .navigationTitle("\(destinationName) Plan")
        .task {
            await loadSavedActivities()
        }
    }

    private var activeBackendBaseURL: String {
        planAPIService.baseURLString
    }

    @ViewBuilder
    private var debugBackendSection: some View {
        #if DEBUG
        // TODO: Remove this debug-only backend display before broader external release builds.
        Text("DEBUG Backend: \(activeBackendBaseURL)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal)
        #endif
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
                .fill(Color.brandSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.brandSage.opacity(0.12), lineWidth: 1)
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
                    .fill(Color.brandSurface)

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
                    .background(Color.clear)
                    .accessibilityLabel("Day plan request")
                    .accessibilityHint("Describe how you want to spend your day in the city.")
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.brandSage.opacity(0.12), lineWidth: 1)
            )
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
                        .fill(isSelected ? Color.brandSage : Color.brandSurface)
                )
                .foregroundStyle(isSelected ? Color.brandGreenDark : Color.primary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(preference.title)
        .accessibilityHint("Adds this preference to your itinerary request.")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                Task {
                    await generateItinerary()
                }
            } label: {
                HStack {
                    if isLoading && itinerary == nil {
                        ProgressView()
                            .accessibilityHidden(true)
                    }

                    Text(isLoading && itinerary == nil ? "Generating..." : "Generate Itinerary")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.brandGreenDark)
            .disabled(canGenerate == false || isLoading)
            .accessibilityLabel("Generate itinerary")
            .accessibilityHint("Generates a day plan using your prompt and selected preferences.")

            if itinerary != nil {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Edit your preferences and regenerate to refine your plan")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        Task {
                            await regenerateItinerary()
                        }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .accessibilityHidden(true)
                            }

                            Text(isLoading ? "Regenerating..." : "Regenerate Plan")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.brandSage)
                    .disabled(canGenerate == false || isLoading)
                    .accessibilityLabel("Regenerate itinerary")
                    .accessibilityHint("Creates a new plan using your current preferences")
                }
            }
        }
        .padding(.horizontal)
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
                                    ? Color.brandSage.opacity(0.26)
                                    : Color.brandSurface
                                )
                        )
                        .foregroundStyle(isEntireItinerarySaved ? Color.brandGreenDark : Color.primary)
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

            HStack {
                Spacer()

                Button {
                    saveCurrentItinerary()
                } label: {
                    Label(isCurrentItineraryPersisted ? "Saved" : "Save Itinerary", systemImage: isCurrentItineraryPersisted ? "checkmark.circle.fill" : "square.and.arrow.down")
                        .font(.subheadline.weight(.semibold))
                        .labelStyle(.titleAndIcon)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(
                                    isCurrentItineraryPersisted
                                    ? Color.brandPink.opacity(0.24)
                                    : Color.brandSurface
                                )
                        )
                        .foregroundStyle(isCurrentItineraryPersisted ? Color.brandGreenDark : Color.primary)
                }
                .buttonStyle(.plain)
                .disabled(isCurrentItineraryPersisted || itinerary == nil)
                .accessibilityLabel("Save itinerary")
                .accessibilityHint("Stores this itinerary for later")
                .accessibilityValue(isCurrentItineraryPersisted ? "Saved" : "Not saved")
            }
            .padding(.horizontal)

            timelineOverview
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
                                    .foregroundStyle(Color.brandSage)
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
                            .fill(Color.brandSurface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.brandSage.opacity(0.12), lineWidth: 1)
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
                        .fill(Color.brandSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.brandPink.opacity(0.12), lineWidth: 1)
                )
                .padding(.horizontal)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var savedItinerariesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saved Itineraries")
                .font(.headline)
                .padding(.horizontal)

            if savedItineraries.isEmpty {
                ContentUnavailableView(
                    "No Saved Itineraries",
                    systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                    description: Text("Save a generated itinerary to revisit it later in \(destinationName).")
                )
                .padding(.horizontal)
            } else {
                VStack(spacing: 12) {
                    ForEach(savedItineraries) { savedItinerary in
                        savedItineraryRow(for: savedItinerary)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var timelineOverview: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Timeline")
                .font(.headline)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(itinerarySections.enumerated()), id: \.element.id) { index, section in
                    timelineSection(section, isLast: index == itinerarySections.count - 1)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.brandSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.brandSage.opacity(0.12), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }

    private func timelineSection(_ section: PlanSection, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.brandSage)
                    .frame(width: 12, height: 12)
                    .padding(.top, 6)
                    .accessibilityHidden(true)

                if isLast == false {
                    Rectangle()
                        .fill(Color.brandSage.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.top, 6)
                        .accessibilityHidden(true)
                } else {
                    EmptyView()
                }
            }
            .frame(width: 12)

            VStack(alignment: .leading, spacing: 10) {
                Text(section.title)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(Array(section.activities.enumerated()), id: \.offset) { index, activity in
                    Text("\(index + 1). \(activity)")
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.bottom, isLast ? 0 : 18)
        }
        // TODO: attach actual time slots when itinerary responses include timing metadata.
        .accessibilityElement(children: .contain)
    }

    private func errorCard(message: String) -> some View {
        Text(message)
            .font(.footnote)
            .foregroundStyle(.red)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.brandSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.brandPink.opacity(0.16), lineWidth: 1)
            )
            .padding(.horizontal)
            .accessibilityLabel("Planner error. \(message)")
    }

    private func savedItineraryRow(for savedItinerary: SavedItinerary) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                loadSavedItinerary(savedItinerary)
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    Text(savedItinerary.createdAt, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(savedItineraryPromptPreview(for: savedItinerary))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(savedItineraryAccessibilityLabel(for: savedItinerary))
            .accessibilityHint("Loads this saved itinerary into the planner.")

            Button(role: .destructive) {
                deleteSavedItinerary(savedItinerary)
            } label: {
                Image(systemName: "trash")
                    .font(.headline)
                    .frame(width: 44, height: 44)
                    .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete saved itinerary")
            .accessibilityHint("Removes this saved itinerary.")
        }
    }

    private func saveActivityButton(for activity: String) -> some View {
        let isSaved = savedActivityNames.contains(savedActivityIdentifier(activity))

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
                        .fill(isSaved ? Color.brandSage.opacity(0.24) : Color.brandSurface)
                )
                .foregroundStyle(isSaved ? Color.brandGreenDark : Color.primary)
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
        do {
            savedActivityNames = try persistenceCoordinator.loadSavedActivityNames()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveActivity(_ activity: String) {
        let trimmedActivity = savedActivityIdentifier(activity)

        guard savedActivityNames.contains(trimmedActivity) == false else {
            return
        }

        do {
            if let savedName = try persistenceCoordinator.saveActivityIfNeeded(activity) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    _ = savedActivityNames.insert(savedName)
                }
            }
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
            let savedNames = try persistenceCoordinator.saveAllActivitiesIfNeeded(activitiesToSave)

            withAnimation(.easeInOut(duration: 0.2)) {
                savedActivityNames.formUnion(savedNames)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func normalizedActivityName(_ activity: String) -> String {
        PlanSavedPlaceSupport.normalizedActivityName(activity)
    }

    private func savedActivityIdentifier(_ activity: String) -> String {
        PlanSavedPlaceSupport.resolvedActivityName(
            for: activity,
            resolveSavedPlace: resolvedSavedPlace
        )
    }

    private func saveCurrentItinerary() {
        guard let itinerary else { return }

        do {
            let savedItinerary = try persistenceCoordinator.saveCurrentItinerary(
                itinerary: itinerary,
                prompt: trimmedPrompt,
                selectedPreferences: selectedPreferences
            )
            persistedItinerarySignature = persistenceCoordinator.signature(for: savedItinerary)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadSavedItinerary(_ savedItinerary: SavedItinerary) {
        prompt = savedItinerary.prompt
        selectedPreferences = Set(
            savedItinerary.preferences.compactMap(PlanPreference.init(rawValue:))
        )
        itinerary = PlanAPIService.ItineraryResponse(
            destination: savedItinerary.destinationName,
            morning: .init(title: savedItinerary.morningTitle, activities: savedItinerary.morningActivities),
            afternoon: .init(title: savedItinerary.afternoonTitle, activities: savedItinerary.afternoonActivities),
            evening: .init(title: savedItinerary.eveningTitle, activities: savedItinerary.eveningActivities),
            notes: savedItinerary.notes
        )
        persistedItinerarySignature = signature(for: savedItinerary)
    }

    private func deleteSavedItinerary(_ savedItinerary: SavedItinerary) {
        do {
            let deletedSignature = try persistenceCoordinator.deleteSavedItinerary(savedItinerary)

            if persistedItinerarySignature == deletedSignature {
                persistedItinerarySignature = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func signature(for savedItinerary: SavedItinerary) -> String {
        persistenceCoordinator.signature(for: savedItinerary)
    }

    private func savedItineraryPromptPreview(for savedItinerary: SavedItinerary) -> String {
        let trimmedPrompt = savedItinerary.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedPrompt.isEmpty == false else {
            let preferences = savedItinerary.preferences
                .compactMap(PlanPreference.init(rawValue:))
                .map(\.title)

            return preferences.isEmpty ? "Saved itinerary" : preferences.joined(separator: ", ")
        }

        return trimmedPrompt
    }

    private func savedItineraryAccessibilityLabel(for savedItinerary: SavedItinerary) -> String {
        "Saved itinerary from \(savedItinerary.createdAt.formatted(date: .abbreviated, time: .shortened)). \(savedItineraryPromptPreview(for: savedItinerary))"
    }

    private func resolvedSavedPlace(for activity: String) -> ResolvedItineraryPlace {
        if let poi = ItineraryPlaceMatcher.match(destinationName: destinationName, activityText: activity) {
            #if DEBUG
            print("ItineraryPlaceMatcher matched '\(activity)' to '\(poi.name)' in \(destinationName)")
            #endif
            return ResolvedItineraryPlace(
                name: poi.name,
                category: poi.category,
                latitude: poi.latitude,
                longitude: poi.longitude
            )
        }

        #if DEBUG
        print("ItineraryPlaceMatcher used fallback for '\(activity)' in \(destinationName)")
        #endif
        return ResolvedItineraryPlace(
            name: activity,
            category: ItineraryCategoryInference.inferCategory(from: activity),
            latitude: 0,
            longitude: 0
        )
    }

    @MainActor
    private func generateItinerary() async {
        await requestItinerary(resetPersistedSignature: true)
    }

    @MainActor
    private func regenerateItinerary() async {
        await requestItinerary(resetPersistedSignature: true)
    }

    @MainActor
    private func requestItinerary(resetPersistedSignature: Bool) async {
        guard isLoading == false else { return }

        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        if resetPersistedSignature {
            persistedItinerarySignature = nil
        }

        do {
            let savedPlaces = try persistenceCoordinator.savedPlaceNamesForRequest()
            let nextItinerary = try await planAPIService.generateItinerary(
                destination: destinationName,
                prompt: trimmedPrompt,
                preferences: selectedPreferences
                    .sorted { $0.title < $1.title }
                    .map(\.title),
                savedPlaces: savedPlaces
            )

            withAnimation(.easeInOut(duration: 0.25)) {
                itinerary = nextItinerary
            }
            await loadSavedActivities()
        } catch {
            errorMessage = userFacingPlannerErrorMessage(for: error)
        }
    }

    private func userFacingPlannerErrorMessage(for error: Error) -> String {
        if let serviceError = error as? PlanAPIService.ServiceError {
            switch serviceError {
            case .transportError:
                return "Itinerary generation is unavailable right now because CityScout cannot reach the planner backend. Please try again shortly once a reachable backend host is available."
            case .rateLimited:
                return "Itinerary generation is busy right now. Please try again in a moment."
            case .unauthorized, .forbidden:
                return "Itinerary generation is unavailable because the planner backend configuration is not accepted right now."
            case .emptyResponse, .decodingFailed, .invalidResponse:
                return "Itinerary generation is unavailable because CityScout received an unexpected planner response."
            default:
                return serviceError.localizedDescription
            }
        }

        return error.localizedDescription
    }
}

struct ResolvedItineraryPlace {
    let name: String
    let category: POICategory?
    let latitude: Double
    let longitude: Double
}

#Preview {
    NavigationStack {
        PlanHomeView(destinationName: "Paris")
    }
}
