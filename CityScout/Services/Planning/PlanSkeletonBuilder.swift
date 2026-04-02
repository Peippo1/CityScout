import Foundation

struct PlanSkeletonBuilder {
    func skeleton(for context: PlanningContext, candidateCount: Int) -> PlanSkeleton {
        var morningCount = 0
        var afternoonCount = 0
        var eveningCount = 0

        switch candidateCount {
        case 0:
            break
        case 1:
            morningCount = 1
        case 2:
            morningCount = 1
            eveningCount = 1
        case 3:
            morningCount = 1
            afternoonCount = 1
            eveningCount = 1
        case 4:
            morningCount = 1
            afternoonCount = 2
            eveningCount = 1
        case 5:
            morningCount = 2
            afternoonCount = 2
            eveningCount = 1
        default:
            morningCount = 2
            afternoonCount = 2
            eveningCount = 2
        }

        let preferences = context.normalizedPreferences
        let prompt = context.prompt.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)

        if preferences.contains(PlanPreference.relaxed.rawValue) || prompt.contains("relaxed") {
            afternoonCount = max(afternoonCount - 1, 1)
        }

        if preferences.contains(PlanPreference.foodFocused.rawValue) || prompt.contains("food") {
            eveningCount = min(max(eveningCount, 2), candidateCount)
        }

        if preferences.contains(PlanPreference.nightOut.rawValue) || prompt.contains("night") {
            eveningCount = min(max(eveningCount, 2), candidateCount)
        }

        let total = morningCount + afternoonCount + eveningCount
        let overflow = max(total - candidateCount, 0)

        if overflow > 0 {
            afternoonCount = max(afternoonCount - overflow, 0)
        }

        return PlanSkeleton(
            morningCount: morningCount,
            afternoonCount: afternoonCount,
            eveningCount: eveningCount
        )
    }
}
