import Foundation

extension SavedPlace {
    var isMappedItineraryPlace: Bool {
        isItineraryDerived && latitude != 0 && longitude != 0
    }

    var isUnmatchedItineraryPlace: Bool {
        isItineraryDerived && latitude == 0 && longitude == 0
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
