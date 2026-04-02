import Foundation

extension SavedPlace {
    var hasUsableMapCoordinate: Bool {
        latitude != 0 && longitude != 0
    }

    var isMappedItineraryPlace: Bool {
        isItineraryDerived && hasUsableMapCoordinate
    }

    var isUnmatchedItineraryPlace: Bool {
        isItineraryDerived && hasUsableMapCoordinate == false
    }

    var itineraryStatusText: String? {
        if isMappedItineraryPlace {
            return "Mapped from itinerary"
        }

        if isUnmatchedItineraryPlace {
            return "Saved from itinerary - location not matched yet"
        }

        return nil
    }

    var itineraryBadgeText: String? {
        if isMappedItineraryPlace {
            return "From itinerary • Mapped"
        }

        if isUnmatchedItineraryPlace {
            return "From itinerary • Not mapped yet"
        }

        return nil
    }

    var itineraryAccessibilityState: String? {
        if isMappedItineraryPlace {
            return "from itinerary, mapped"
        }

        if isUnmatchedItineraryPlace {
            return "from itinerary, not mapped yet"
        }

        if isItineraryDerived {
            return "from itinerary"
        }

        return nil
    }
}
