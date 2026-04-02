import Foundation

struct PlanningNarrativeBuilder {
    func narrative(for itinerary: LocalPlannedItinerary) -> String? {
        let categories = itinerary.sections
            .flatMap(\.items)
            .compactMap { item in
                switch item.mappingStatus {
                case .matchedPOI:
                    return item.title
                case .fallback:
                    return nil
                }
            }

        guard categories.isEmpty == false else {
            return nil
        }

        if itinerary.evening.items.isEmpty == false {
            return "Your \(itinerary.destination) day is shaping up with a steady rhythm from morning stops through a relaxed evening."
        }

        return "Your \(itinerary.destination) plan is taking shape with a balanced spread across the day."
    }
}
