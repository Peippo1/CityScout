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

    var activityPhrase: String {
        switch self {
        case .relaxed:
            return "a slower-paced neighborhood wander"
        case .foodFocused:
            return "a food stop with local specialties"
        case .sightseeing:
            return "one of the city's headline sights"
        case .cafes:
            return "a cafe break"
        case .nightOut:
            return "an evening spot with lively energy"
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

    private let preferenceColumns = [
        GridItem(.adaptive(minimum: 140), spacing: 10, alignment: .leading)
    ]

    @State private var prompt = ""
    @State private var selectedPreferences: Set<PlanPreference> = []
    @State private var itinerary: [PlanSection] = []

    private var trimmedPrompt: String {
        prompt.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canGenerate: Bool {
        trimmedPrompt.isEmpty == false || selectedPreferences.isEmpty == false
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

                if itinerary.isEmpty == false {
                    itinerarySection
                }
            }
            .padding(.bottom)
        }
        .navigationTitle("\(destinationName) Plan")
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
            itinerary = makeItinerary()
        } label: {
            Text("Generate Itinerary")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(canGenerate == false)
        .padding(.horizontal)
        .accessibilityLabel("Generate itinerary")
        .accessibilityHint("Creates a simple day plan using your prompt and selected preferences.")
    }

    private var itinerarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggested Plan")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(itinerary) { section in
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
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.horizontal)
        }
    }

    private func makeItinerary() -> [PlanSection] {
        let selected = PlanPreference.allCases.filter { selectedPreferences.contains($0) }
        let firstPreference = selected.first?.activityPhrase ?? "a comfortable local start"
        let secondPreference = selected.dropFirst().first?.activityPhrase ?? "a local neighborhood to explore"
        let eveningPreference = selected.contains(.nightOut)
            ? PlanPreference.nightOut.activityPhrase
            : (selected.contains(.foodFocused) ? "dinner in \(destinationName)" : "a relaxed walk in \(destinationName)")

        let promptActivity: String
        if trimmedPrompt.isEmpty {
            promptActivity = "Set your pace with \(firstPreference) in \(destinationName)."
        } else {
            promptActivity = "Start with a plan inspired by “\(trimmedPrompt)”."
        }

        return [
            PlanSection(
                title: "Morning",
                activities: [
                    promptActivity,
                    "Begin with \(selected.contains(.cafes) ? "coffee in \(destinationName)" : secondPreference)."
                ]
            ),
            PlanSection(
                title: "Afternoon",
                activities: [
                    "Spend the afternoon around \(selected.contains(.sightseeing) ? "one of the main sights in \(destinationName)" : "a local area worth exploring").",
                    "Pause for \(selected.contains(.foodFocused) ? "a meal that highlights local flavors" : "lunch and a short recharge")."
                ]
            ),
            PlanSection(
                title: "Evening",
                activities: [
                    "Wrap up with \(eveningPreference).",
                    "Leave time for a flexible stop that matches your mood in \(destinationName)."
                ]
            )
        ]
    }
}

#Preview {
    NavigationStack {
        PlanHomeView(destinationName: "Paris")
    }
}
