import SwiftUI
import SwiftData

struct POIDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var savedPlaces: [SavedPlace]

    let poi: PointOfInterest
    let destinationName: String

    @State private var isShowingSaveAlert = false
    @State private var saveAlertMessage = ""

    init(poi: PointOfInterest, destinationName: String) {
        self.poi = poi
        self.destinationName = destinationName
        _savedPlaces = Query(
            filter: #Predicate { place in
                place.destinationName == destinationName
            },
            sort: [SortDescriptor(\SavedPlace.createdAt, order: .reverse)]
        )
    }

    private var isSaved: Bool {
        SavedPlaceService.isPlaceSaved(
            name: poi.name,
            destinationName: destinationName,
            in: savedPlaces
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: poi.symbolName)
                    .font(.system(size: 56))
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)

                Text(poi.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .fixedSize(horizontal: false, vertical: true)

                Text(poi.shortDescription)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    saveToMap()
                } label: {
                    Label(
                        isSaved ? "Saved to Map" : "Save to Map",
                        systemImage: isSaved ? "bookmark.fill" : "mappin.and.ellipse"
                    )
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaved)
                .accessibilityLabel("Save \(poi.name) to map")
                .accessibilityHint("Adds this point of interest to your saved places.")
            }
            .padding()
            .accessibilityElement(children: .contain)
        }
        .navigationTitle(poi.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Saved Place", isPresented: $isShowingSaveAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveAlertMessage)
        }
    }

    private func saveToMap() {
        do {
            let savedPlace = try SavedPlaceService.savePlaceIfNeeded(
                name: poi.name,
                category: poi.category,
                source: SavedPlace.Source.poi.rawValue,
                destinationName: destinationName,
                latitude: poi.latitude,
                longitude: poi.longitude,
                in: modelContext
            )
            saveAlertMessage = savedPlace == nil
            ? "\(poi.name) is already saved for \(destinationName)."
            : "\(poi.name) was saved to your map."
        } catch {
            saveAlertMessage = "Could not save this place right now."
        }
        isShowingSaveAlert = true
    }
}

#Preview {
    NavigationStack {
        POIDetailView(
            poi: PointOfInterest(
                city: "Paris",
                category: .sights,
                name: "Eiffel Tower",
                shortDescription: "Iconic wrought-iron landmark with panoramic city views.",
                symbolName: "tower",
                latitude: 48.8584,
                longitude: 2.2945
            ),
            destinationName: "Paris"
        )
    }
}
