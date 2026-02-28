import SwiftUI
import SwiftData
import MapKit

struct MapHomeView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\SavedPlace.createdAt, order: .reverse)])
    private var savedPlaces: [SavedPlace]

    @State private var position: MapCameraPosition = .automatic
    @State private var pendingCoordinate: CLLocationCoordinate2D?
    @State private var pendingPlaceName = ""
    @State private var isShowingSaveSheet = false

    var body: some View {
        MapReader { proxy in
            Map(position: $position) {
                ForEach(savedPlaces) { place in
                    Marker(
                        place.name,
                        coordinate: CLLocationCoordinate2D(
                            latitude: place.latitude,
                            longitude: place.longitude
                        )
                    )
                }

                if let pendingCoordinate {
                    Annotation("New Place", coordinate: pendingCoordinate) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.red)
                    }
                }
            }
            .gesture(longPressGesture(with: proxy))
            .sheet(isPresented: $isShowingSaveSheet) {
                savePlaceSheet
            }
            .navigationTitle("Map")
        }
    }

    private var savePlaceSheet: some View {
        NavigationStack {
            Form {
                Section("Place Name") {
                    TextField("e.g. Favorite Cafe", text: $pendingPlaceName)
                        .textInputAutocapitalization(.words)
                }
            }
            .navigationTitle("Save Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        clearPendingPlace()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        savePendingPlace()
                    }
                    .disabled(trimmedPendingName.isEmpty || pendingCoordinate == nil)
                }
            }
        }
    }

    private var trimmedPendingName: String {
        pendingPlaceName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func longPressGesture(with proxy: MapProxy) -> some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
            .onEnded { value in
                guard case .second(true, let drag?) = value else { return }
                guard let coordinate = proxy.convert(drag.location, from: .local) else { return }

                pendingCoordinate = coordinate
                pendingPlaceName = ""
                isShowingSaveSheet = true
            }
    }

    private func savePendingPlace() {
        guard let coordinate = pendingCoordinate else { return }
        guard !trimmedPendingName.isEmpty else { return }

        do {
            try SavedPlaceService.savePlace(
                name: trimmedPendingName,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                in: modelContext
            )
            clearPendingPlace()
        } catch {
            assertionFailure("Failed to save place: \(error.localizedDescription)")
        }
    }

    private func clearPendingPlace() {
        pendingCoordinate = nil
        pendingPlaceName = ""
        isShowingSaveSheet = false
    }
}

#Preview {
    NavigationStack {
        MapHomeView()
    }
}
