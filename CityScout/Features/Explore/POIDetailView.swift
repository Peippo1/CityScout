import SwiftUI
import SwiftData

struct POIDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let poi: PointOfInterest
    let destinationName: String

    @State private var isShowingSaveAlert = false
    @State private var saveAlertMessage = ""

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
                    Label("Save to Map", systemImage: "mappin.and.ellipse")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
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
            try SavedPlaceService.savePlace(
                name: poi.name,
                category: poi.category,
                destinationName: destinationName,
                latitude: poi.latitude,
                longitude: poi.longitude,
                in: modelContext
            )
            saveAlertMessage = "\(poi.name) was saved to your map."
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
