import Foundation

struct LocalRouteOptimizer {
    static func optimize(_ candidates: [PlanningCandidate]) -> [PlanningCandidate] {
        guard candidates.count > 1 else { return candidates }

        var mappedCandidates = candidates.filter(\.hasCoordinates)
        let fallbackCandidates = candidates.filter { $0.hasCoordinates == false }

        guard mappedCandidates.count > 1 else {
            return mappedCandidates + fallbackCandidates
        }

        var orderedCandidates: [PlanningCandidate] = [mappedCandidates.removeFirst()]

        while mappedCandidates.isEmpty == false, let currentCandidate = orderedCandidates.last {
            let nextIndex = mappedCandidates.enumerated().min { lhs, rhs in
                distance(from: currentCandidate, to: lhs.element) < distance(from: currentCandidate, to: rhs.element)
            }?.offset

            guard let nextIndex else { break }
            orderedCandidates.append(mappedCandidates.remove(at: nextIndex))
        }

        return orderedCandidates + fallbackCandidates
    }

    private static func distance(from lhs: PlanningCandidate, to rhs: PlanningCandidate) -> Double {
        let latitudeDelta = lhs.latitude - rhs.latitude
        let longitudeDelta = lhs.longitude - rhs.longitude
        return (latitudeDelta * latitudeDelta) + (longitudeDelta * longitudeDelta)
    }
}
