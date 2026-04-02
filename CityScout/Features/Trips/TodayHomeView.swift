import MapKit
import SwiftData
import SwiftUI

enum TodayActivityState: String {
    case upcoming
    case visited
    case skipped

    var title: String {
        switch self {
        case .upcoming:
            return "Upcoming"
        case .visited:
            return "Visited"
        case .skipped:
            return "Skipped"
        }
    }

    var tint: Color {
        switch self {
        case .upcoming:
            return .brandSage
        case .visited:
            return .brandGreenDark
        case .skipped:
            return .orange
        }
    }

    var symbol: String {
        switch self {
        case .upcoming:
            return "clock.fill"
        case .visited:
            return "checkmark.circle.fill"
        case .skipped:
            return "forward.circle.fill"
        }
    }
}

private struct TodayActivity: Identifiable {
    let id: String
    let sectionTitle: String
    let title: String
    let index: Int
}

enum TodayProgressStore {
    private static let defaults = UserDefaults.standard

    static func selectedItineraryID(for destinationName: String) -> UUID? {
        guard let rawValue = defaults.string(forKey: selectedItineraryKey(destinationName: destinationName)) else {
            return nil
        }

        return UUID(uuidString: rawValue)
    }

    static func setSelectedItineraryID(_ id: UUID?, for destinationName: String) {
        let key = selectedItineraryKey(destinationName: destinationName)
        if let id {
            defaults.set(id.uuidString, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    static func activityState(for activityID: String, itineraryID: UUID) -> TodayActivityState {
        let states = storedStates(itineraryID: itineraryID)
        return states[activityID].flatMap(TodayActivityState.init(rawValue:)) ?? .upcoming
    }

    static func setActivityState(_ state: TodayActivityState, for activityID: String, itineraryID: UUID) {
        var states = storedStates(itineraryID: itineraryID)
        states[activityID] = state.rawValue
        defaults.set(states, forKey: activityStatesKey(itineraryID: itineraryID))
    }

    static func reset(itineraryID: UUID, destinationName: String) {
        defaults.removeObject(forKey: selectedItineraryKey(destinationName: destinationName))
        defaults.removeObject(forKey: activityStatesKey(itineraryID: itineraryID))
    }

    private static func selectedItineraryKey(destinationName: String) -> String {
        "today.itinerary.\(destinationName)"
    }

    private static func activityStatesKey(itineraryID: UUID) -> String {
        "today.activityStates.\(itineraryID.uuidString)"
    }

    private static func storedStates(itineraryID: UUID) -> [String: String] {
        defaults.dictionary(forKey: activityStatesKey(itineraryID: itineraryID)) as? [String: String] ?? [:]
    }
}

struct TodayHomeView: View {
    let destinationName: String

    @Query private var savedItineraries: [SavedItinerary]
    @State private var selectedItineraryID: UUID?
    @State private var activityStates: [String: TodayActivityState] = [:]

    init(destinationName: String) {
        self.destinationName = destinationName
        _savedItineraries = Query(
            filter: #Predicate { itinerary in
                itinerary.destinationName == destinationName
            },
            sort: [SortDescriptor(\SavedItinerary.createdAt, order: .reverse)]
        )
    }

    private var destinationItineraries: [SavedItinerary] {
        savedItineraries.filter { $0.destinationName == destinationName }
    }

    private var selectedItinerary: SavedItinerary? {
        if let selectedItineraryID {
            return destinationItineraries.first { $0.id == selectedItineraryID }
        }

        return destinationItineraries.first
    }

    private var itineraryActivities: [TodayActivity] {
        guard let selectedItinerary else { return [] }

        let sections = [
            (selectedItinerary.morningTitle, selectedItinerary.morningActivities),
            (selectedItinerary.afternoonTitle, selectedItinerary.afternoonActivities),
            (selectedItinerary.eveningTitle, selectedItinerary.eveningActivities)
        ]

        return sections.flatMap { sectionTitle, activities in
            activities.enumerated().map { index, activity in
                TodayActivity(
                    id: "\(sectionTitle)|\(index)|\(activity)",
                    sectionTitle: sectionTitle,
                    title: activity,
                    index: index
                )
            }
        }
    }

    private var nextUpcomingActivity: TodayActivity? {
        guard let itineraryID = selectedItinerary?.id else { return nil }
        return itineraryActivities.first { activity in
            TodayProgressStore.activityState(for: activity.id, itineraryID: itineraryID) == .upcoming
        }
    }

    var body: some View {
        Group {
            if destinationItineraries.isEmpty {
                ContentUnavailableView(
                    "No Itinerary For Today",
                    systemImage: "sun.max",
                    description: Text("Save an itinerary in \(destinationName) to turn it into today’s plan.")
                )
            } else if let selectedItinerary {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        todayHeader(for: selectedItinerary)

                        if let nextUpcomingActivity {
                            nextStopCard(for: nextUpcomingActivity, itineraryID: selectedItinerary.id)
                        }

                        itineraryProgressList(for: selectedItinerary)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
                .background(Color.brandCream.ignoresSafeArea())
                .navigationTitle("Today")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .task {
            let storedID = TodayProgressStore.selectedItineraryID(for: destinationName)
            selectedItineraryID = storedID ?? destinationItineraries.first?.id
            if let selectedItinerary {
                TodayProgressStore.setSelectedItineraryID(selectedItinerary.id, for: destinationName)
                reloadActivityStates(for: selectedItinerary.id)
            }
        }
        .onChange(of: selectedItineraryID) { _, newValue in
            TodayProgressStore.setSelectedItineraryID(newValue, for: destinationName)
            if let newValue {
                reloadActivityStates(for: newValue)
            }
        }
    }

    private func todayHeader(for itinerary: SavedItinerary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(displayTitle(for: itinerary))
                .font(.title3.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)

            Text(itinerary.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Use this saved itinerary as your plan for today." : itinerary.prompt)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if destinationItineraries.count > 1 {
                Picker("Today itinerary", selection: Binding(
                    get: { selectedItineraryID ?? itinerary.id },
                    set: { selectedItineraryID = $0 }
                )) {
                    ForEach(destinationItineraries) { savedItinerary in
                        Text(displayTitle(for: savedItinerary)).tag(savedItinerary.id)
                    }
                }
                .pickerStyle(.menu)
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
    }

    private func nextStopCard(for activity: TodayActivity, itineraryID: UUID) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Next Stop")
                .font(.headline)

            Text(activity.title)
                .font(.title3.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)

            Text(activity.sectionTitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    openInMapsButton(for: activity)
                    stateButton(title: "Visited", state: .visited, activity: activity, itineraryID: itineraryID)
                    stateButton(title: "Skip", state: .skipped, activity: activity, itineraryID: itineraryID)
                }

                VStack(spacing: 10) {
                    openInMapsButton(for: activity)
                    stateButton(title: "Visited", state: .visited, activity: activity, itineraryID: itineraryID)
                    stateButton(title: "Skip", state: .skipped, activity: activity, itineraryID: itineraryID)
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
                .stroke(Color.brandPink.opacity(0.12), lineWidth: 1)
        )
    }

    private func itineraryProgressList(for itinerary: SavedItinerary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today’s Plan")
                .font(.headline)

            ForEach(itineraryActivities) { activity in
                let state = activityStates[activity.id] ?? .upcoming

                HStack(alignment: .top, spacing: 12) {
                    Label(state.title, systemImage: state.symbol)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(state.tint.opacity(0.16), in: Capsule(style: .continuous))
                        .foregroundStyle(state.tint)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(activity.title)
                            .font(.body.weight(nextUpcomingActivity?.id == activity.id ? .semibold : .regular))
                            .fixedSize(horizontal: false, vertical: true)

                        Text(activity.sectionTitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 8)

                    Menu {
                        Button("Mark Visited") {
                            updateState(.visited, for: activity, itineraryID: itinerary.id)
                        }
                        Button("Skip") {
                            updateState(.skipped, for: activity, itineraryID: itinerary.id)
                        }
                        Button("Reset") {
                            updateState(.upcoming, for: activity, itineraryID: itinerary.id)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.brandSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.brandSage.opacity(0.12), lineWidth: 1)
                )
            }
        }
    }

    private func openInMapsButton(for activity: TodayActivity) -> some View {
        Button("Open in Map") {
            openInMaps(for: activity.title)
        }
        .buttonStyle(.borderedProminent)
        .tint(.brandGreenDark)
        .disabled(resolvedPlace(for: activity.title).latitude == 0 && resolvedPlace(for: activity.title).longitude == 0)
    }

    private func stateButton(
        title: String,
        state: TodayActivityState,
        activity: TodayActivity,
        itineraryID: UUID
    ) -> some View {
        Button(title) {
            updateState(state, for: activity, itineraryID: itineraryID)
        }
        .buttonStyle(.bordered)
        .tint(state.tint)
    }

    private func updateState(_ state: TodayActivityState, for activity: TodayActivity, itineraryID: UUID) {
        TodayProgressStore.setActivityState(state, for: activity.id, itineraryID: itineraryID)
        activityStates[activity.id] = state
    }

    private func reloadActivityStates(for itineraryID: UUID) {
        activityStates = Dictionary(uniqueKeysWithValues: itineraryActivities.map { activity in
            (activity.id, TodayProgressStore.activityState(for: activity.id, itineraryID: itineraryID))
        })
    }

    private func displayTitle(for itinerary: SavedItinerary) -> String {
        let trimmedTitle = itinerary.customTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty == false {
            return trimmedTitle
        }

        let trimmedPrompt = itinerary.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedPrompt.isEmpty == false {
            return trimmedPrompt
        }

        let preferences = itinerary.preferences
            .compactMap(PlanPreference.init(rawValue:))
            .map(\.title)

        return preferences.isEmpty ? "Saved itinerary" : preferences.joined(separator: ", ")
    }

    private func resolvedPlace(for activity: String) -> ResolvedItineraryPlace {
        if let poi = ItineraryPlaceMatcher.match(destinationName: destinationName, activityText: activity) {
            return ResolvedItineraryPlace(
                name: poi.name,
                category: poi.category,
                latitude: poi.latitude,
                longitude: poi.longitude
            )
        }

        return ResolvedItineraryPlace(
            name: activity,
            category: ItineraryCategoryInference.inferCategory(from: activity),
            latitude: 0,
            longitude: 0
        )
    }

    private func openInMaps(for activity: String) {
        let resolved = resolvedPlace(for: activity)
        guard resolved.latitude != 0 || resolved.longitude != 0 else { return }

        let placemark = MKPlacemark(
            coordinate: CLLocationCoordinate2D(latitude: resolved.latitude, longitude: resolved.longitude)
        )
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = resolved.name
        mapItem.openInMaps()
    }
}

#Preview {
    NavigationStack {
        TodayHomeView(destinationName: "Paris")
    }
}
