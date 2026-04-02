import Combine
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

private struct PlanFeedbackMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let symbol: String
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

    static func orderedUniqueActivityNames(from activities: [String]) -> [String] {
        var seenActivities: Set<String> = []
        var orderedActivities: [String] = []

        for activity in activities {
            let normalizedActivity = normalizedActivityName(activity)
            guard normalizedActivity.isEmpty == false else { continue }
            guard seenActivities.insert(normalizedActivity).inserted else { continue }

            orderedActivities.append(activity.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return orderedActivities
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

        var existingPlaceNames = try fetchSavedPlaceIdentifiersForDestination()
        let insertedPlace = try insertResolvedPlaceIfNeeded(
            for: activity,
            existingPlaceNames: &existingPlaceNames
        )

        if insertedPlace != nil {
            try modelContext.save()
        }

        return normalizedActivity
    }

    func saveAllActivitiesIfNeeded(_ activities: [String]) throws -> Set<String> {
        guard activities.isEmpty == false else {
            return []
        }

        var existingPlaceNames = try fetchSavedPlaceIdentifiersForDestination()
        var savedNames: Set<String> = []
        var insertedPlaceCount = 0

        for activity in activities {
            let normalizedActivity = resolvedActivityName(for: activity)
            guard normalizedActivity.isEmpty == false else { continue }

            if try insertResolvedPlaceIfNeeded(for: activity, existingPlaceNames: &existingPlaceNames) != nil {
                insertedPlaceCount += 1
            }

            savedNames.insert(normalizedActivity)
        }

        if insertedPlaceCount > 0 {
            try modelContext.save()
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

    private func fetchSavedPlaceIdentifiersForDestination() throws -> Set<String> {
        Set(try fetchSavedPlacesForDestination().map(\.name).map(normalizeActivityName))
    }

    @discardableResult
    private func insertResolvedPlaceIfNeeded(
        for activity: String,
        existingPlaceNames: inout Set<String>
    ) throws -> SavedPlace? {
        let normalizedActivity = normalizeActivityName(activity)
        guard normalizedActivity.isEmpty == false else {
            return nil
        }

        let resolvedPlace = resolveSavedPlace(activity)
        let fallbackName = activity.trimmingCharacters(in: .whitespacesAndNewlines)
        let persistedName = resolvedPlace.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = persistedName.isEmpty ? fallbackName : persistedName
        let normalizedFinalName = normalizeActivityName(finalName)

        guard normalizedFinalName.isEmpty == false else {
            return nil
        }

        guard existingPlaceNames.insert(normalizedFinalName).inserted else {
            return nil
        }

        let savedPlace = SavedPlace(
            name: finalName,
            category: resolvedPlace.category,
            source: SavedPlace.Source.itinerary.rawValue,
            destinationName: destinationName,
            latitude: resolvedPlace.latitude,
            longitude: resolvedPlace.longitude
        )
        modelContext.insert(savedPlace)
        return savedPlace
    }

    private func resolvedActivityName(for activity: String) -> String {
        PlanSavedPlaceSupport.resolvedActivityName(
            for: activity,
            resolveSavedPlace: resolveSavedPlace
        )
    }
}

@MainActor
private final class PlanHomeViewModel: ObservableObject {
    @Published var prompt = ""
    @Published var selectedPreferences: Set<PlanPreference> = []
    @Published var itinerary: PlanAPIService.ItineraryResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var savedActivityNames: Set<String> = []
    @Published var persistedItinerarySignature: String?
    @Published var feedbackMessage: PlanFeedbackMessage?

    private let planAPIService = PlanAPIService()
    private var feedbackDismissTask: Task<Void, Never>?

    deinit {
        feedbackDismissTask?.cancel()
    }

    var trimmedPrompt: String {
        prompt.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canGenerate: Bool {
        trimmedPrompt.isEmpty == false || selectedPreferences.isEmpty == false
    }

    var itinerarySections: [PlanSection] {
        guard let itinerary else { return [] }
        return [
            PlanSection(title: itinerary.morning.title, activities: itinerary.morning.activities),
            PlanSection(title: itinerary.afternoon.title, activities: itinerary.afternoon.activities),
            PlanSection(title: itinerary.evening.title, activities: itinerary.evening.activities)
        ]
    }

    var allItineraryActivities: [String] {
        PlanSavedPlaceSupport.orderedUniqueActivityNames(
            from: itinerarySections.flatMap(\.activities)
        )
    }

    var activeBackendBaseURL: String {
        planAPIService.baseURLString
    }

    func loadSavedActivities(using persistenceCoordinator: PlanPersistenceCoordinator) async {
        do {
            savedActivityNames = try persistenceCoordinator.loadSavedActivityNames()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveActivity(
        _ activity: String,
        activityIdentifier: String,
        using persistenceCoordinator: PlanPersistenceCoordinator
    ) {
        guard savedActivityNames.contains(activityIdentifier) == false else {
            return
        }

        do {
            if let savedName = try persistenceCoordinator.saveActivityIfNeeded(activity) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    _ = savedActivityNames.insert(savedName)
                }
                showFeedback("Saved activity to places", symbol: "bookmark.fill")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveAllActivities(using persistenceCoordinator: PlanPersistenceCoordinator) {
        let activitiesToSave = allItineraryActivities

        guard activitiesToSave.isEmpty == false else {
            return
        }

        do {
            let savedNames = try persistenceCoordinator.saveAllActivitiesIfNeeded(activitiesToSave)

            withAnimation(.easeInOut(duration: 0.2)) {
                savedActivityNames.formUnion(savedNames)
            }

            showFeedback("Saved itinerary activities", symbol: "bookmark.fill")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveCurrentItinerary(using persistenceCoordinator: PlanPersistenceCoordinator) {
        guard let itinerary else { return }

        do {
            let savedItinerary = try persistenceCoordinator.saveCurrentItinerary(
                itinerary: itinerary,
                prompt: trimmedPrompt,
                selectedPreferences: selectedPreferences
            )
            persistedItinerarySignature = persistenceCoordinator.signature(for: savedItinerary)
            showFeedback("Saved itinerary for later", symbol: "square.and.arrow.down.fill")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadSavedItinerary(_ savedItinerary: SavedItinerary, signature: String) {
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
        persistedItinerarySignature = signature
        errorMessage = nil
        showFeedback("Loaded saved itinerary", symbol: "clock.arrow.trianglehead.counterclockwise.rotate.90")
    }

    func deleteSavedItinerary(
        _ savedItinerary: SavedItinerary,
        using persistenceCoordinator: PlanPersistenceCoordinator
    ) {
        do {
            let deletedSignature = try persistenceCoordinator.deleteSavedItinerary(savedItinerary)

            if persistedItinerarySignature == deletedSignature {
                persistedItinerarySignature = nil
            }

            showFeedback("Deleted saved itinerary", symbol: "trash.fill")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func generateItinerary(
        destinationName: String,
        using persistenceCoordinator: PlanPersistenceCoordinator
    ) async {
        await requestItinerary(
            destinationName: destinationName,
            using: persistenceCoordinator,
            resetPersistedSignature: true
        )
    }

    func regenerateItinerary(
        destinationName: String,
        using persistenceCoordinator: PlanPersistenceCoordinator
    ) async {
        await requestItinerary(
            destinationName: destinationName,
            using: persistenceCoordinator,
            resetPersistedSignature: true
        )
    }

    func currentItinerarySignature(for destinationName: String) -> String? {
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

    private func requestItinerary(
        destinationName: String,
        using persistenceCoordinator: PlanPersistenceCoordinator,
        resetPersistedSignature: Bool
    ) async {
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
            await loadSavedActivities(using: persistenceCoordinator)
            showFeedback("Plan ready", symbol: "sparkles")
        } catch {
            errorMessage = userFacingPlannerErrorMessage(for: error)
        }
    }

    private func showFeedback(_ text: String, symbol: String) {
        feedbackDismissTask?.cancel()

        let message = PlanFeedbackMessage(text: text, symbol: symbol)
        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
            feedbackMessage = message
        }

        feedbackDismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            guard Task.isCancelled == false else { return }
            await self?.dismissFeedback(id: message.id)
        }
    }

    private func dismissFeedback(id: UUID) {
        guard feedbackMessage?.id == id else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            feedbackMessage = nil
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

private struct PlanFeedbackBanner: View {
    let feedback: PlanFeedbackMessage

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: feedback.symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.brandGreenDark)
                .accessibilityHidden(true)

            Text(feedback.text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Capsule(style: .continuous)
                .fill(Color.brandSurface)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.brandSage.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(feedback.text)
    }
}

struct PlanHomeView: View {
    let destinationName: String

    @Environment(\.modelContext) private var modelContext
    @Query private var savedItineraries: [SavedItinerary]
    @StateObject private var viewModel = PlanHomeViewModel()

    private let preferenceColumns = [
        GridItem(.adaptive(minimum: 140), spacing: 10, alignment: .leading)
    ]

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

    private var allItineraryActivityIdentifiers: [String] {
        PlanSavedPlaceSupport.orderedUniqueActivityNames(
            from: viewModel.allItineraryActivities.map(savedActivityIdentifier)
        )
    }

    private var isEntireItinerarySaved: Bool {
        allItineraryActivityIdentifiers.isEmpty == false
        && allItineraryActivityIdentifiers.allSatisfy { viewModel.savedActivityNames.contains($0) }
    }

    private var isCurrentItineraryPersisted: Bool {
        guard let currentItinerarySignature = viewModel.currentItinerarySignature(for: destinationName) else {
            return false
        }

        return viewModel.persistedItinerarySignature == currentItinerarySignature
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

                if let errorMessage = viewModel.errorMessage {
                    errorCard(message: errorMessage)
                }

                if viewModel.itinerarySections.isEmpty == false {
                    itinerarySection
                }

                savedItinerariesSection
            }
            .padding(.bottom)
        }
        .background(Color.brandCream.ignoresSafeArea())
        .navigationTitle("\(destinationName) Plan")
        .overlay(alignment: .top) {
            if let feedback = viewModel.feedbackMessage {
                PlanFeedbackBanner(feedback: feedback)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .task {
            await viewModel.loadSavedActivities(using: persistenceCoordinator)
        }
    }

    @ViewBuilder
    private var debugBackendSection: some View {
        #if DEBUG
        // TODO: Remove this debug-only backend display before broader external release builds.
        Text("DEBUG Backend: \(viewModel.activeBackendBaseURL)")
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

                if viewModel.trimmedPrompt.isEmpty {
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

                TextEditor(text: $viewModel.prompt)
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
        let isSelected = viewModel.selectedPreferences.contains(preference)

        return Button {
            if isSelected {
                viewModel.selectedPreferences.remove(preference)
            } else {
                viewModel.selectedPreferences.insert(preference)
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
                    await viewModel.generateItinerary(
                        destinationName: destinationName,
                        using: persistenceCoordinator
                    )
                }
            } label: {
                HStack {
                    if viewModel.isLoading && viewModel.itinerary == nil {
                        ProgressView()
                            .accessibilityHidden(true)
                    }

                    Text(viewModel.isLoading && viewModel.itinerary == nil ? "Generating..." : "Generate Itinerary")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.brandGreenDark)
            .disabled(viewModel.canGenerate == false || viewModel.isLoading)
            .accessibilityLabel("Generate itinerary")
            .accessibilityHint("Generates a day plan using your prompt and selected preferences.")

            if viewModel.itinerary != nil {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Edit your preferences and regenerate to refine your plan")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        Task {
                            await viewModel.regenerateItinerary(
                                destinationName: destinationName,
                                using: persistenceCoordinator
                            )
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .accessibilityHidden(true)
                            }

                            Text(viewModel.isLoading ? "Regenerating..." : "Regenerate Plan")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.brandSage)
                    .disabled(viewModel.canGenerate == false || viewModel.isLoading)
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
                    viewModel.saveAllActivities(using: persistenceCoordinator)
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
                        .opacity((isEntireItinerarySaved || viewModel.isLoading) ? 0.85 : 1)
                        .animation(.easeInOut(duration: 0.2), value: isEntireItinerarySaved)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading || isEntireItinerarySaved)
                .accessibilityLabel("Save all itinerary activities")
                .accessibilityHint("Adds all activities in this itinerary to saved places")
                .accessibilityValue(isEntireItinerarySaved ? "Saved" : "Not saved")
            }
            .padding(.horizontal)

            HStack {
                Spacer()

                Button {
                    viewModel.saveCurrentItinerary(using: persistenceCoordinator)
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
                .disabled(isCurrentItineraryPersisted || viewModel.itinerary == nil)
                .accessibilityLabel("Save itinerary")
                .accessibilityHint("Stores this itinerary for later")
                .accessibilityValue(isCurrentItineraryPersisted ? "Saved" : "Not saved")
            }
            .padding(.horizontal)

            timelineOverview
                .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(viewModel.itinerarySections) { section in
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

            if let notes = viewModel.itinerary?.notes, notes.isEmpty == false {
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
                ForEach(Array(viewModel.itinerarySections.enumerated()), id: \.element.id) { index, section in
                    timelineSection(section, isLast: index == viewModel.itinerarySections.count - 1)
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
                viewModel.loadSavedItinerary(
                    savedItinerary,
                    signature: signature(for: savedItinerary)
                )
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
                viewModel.deleteSavedItinerary(
                    savedItinerary,
                    using: persistenceCoordinator
                )
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
        let activityIdentifier = savedActivityIdentifier(activity)
        let isSaved = viewModel.savedActivityNames.contains(activityIdentifier)

        return Button {
            viewModel.saveActivity(
                activity,
                activityIdentifier: activityIdentifier,
                using: persistenceCoordinator
            )
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

    private func normalizedActivityName(_ activity: String) -> String {
        PlanSavedPlaceSupport.normalizedActivityName(activity)
    }

    private func savedActivityIdentifier(_ activity: String) -> String {
        PlanSavedPlaceSupport.resolvedActivityName(
            for: activity,
            resolveSavedPlace: resolvedSavedPlace
        )
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
