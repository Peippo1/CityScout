import MapKit
import SwiftData
import SwiftUI

struct SavedPlaceDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let place: SavedPlace
    var onDelete: (() -> Void)? = nil

    @State private var errorMessage: String?

    private var sourceLabel: String {
        switch place.source {
        case SavedPlace.Source.poi.rawValue:
            return "Point of interest"
        case SavedPlace.Source.itinerary.rawValue:
            return "Itinerary"
        case SavedPlace.Source.manual.rawValue:
            return "Manual save"
        default:
            return "Saved place"
        }
    }

    private var coordinatesText: String {
        "\(place.latitude.formatted(.number.precision(.fractionLength(4)))), \(place.longitude.formatted(.number.precision(.fractionLength(4))))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Place") {
                    Text(place.name)
                        .font(.title3.weight(.semibold))
                }

                Section("Context") {
                    labelledRow(title: "Destination", value: place.destinationName)
                    labelledRow(title: "Category", value: place.category?.displayName ?? "Saved place")
                    labelledRow(title: "Source", value: sourceLabel)
                }

                Section("Coordinates") {
                    if place.hasUsableMapCoordinate {
                        Text(coordinatesText)
                    } else {
                        Text("No mapped coordinates yet")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Saved") {
                    Text(place.createdAt, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button("Open in Maps") {
                        openInMaps()
                    }
                    .disabled(place.hasUsableMapCoordinate == false)

                    Button("Remove Saved Place", role: .destructive) {
                        deletePlace()
                    }
                }
            }
            .navigationTitle(place.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func labelledRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.body)
        }
    }

    private func openInMaps() {
        let placemark = MKPlacemark(
            coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
        )
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = place.name
        mapItem.openInMaps()
    }

    private func deletePlace() {
        do {
            try SavedPlaceService.deletePlace(place, in: modelContext)
            onDelete?()
            dismiss()
        } catch {
            errorMessage = "Could not remove this saved place right now."
        }
    }
}
