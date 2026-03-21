import SwiftUI
import SwiftData
import MapKit

struct MapHomeView: View {
    let destinationName: String

    @Environment(\.modelContext) private var modelContext

    @Query
    private var savedPlaces: [SavedPlace]

    @State private var position: MapCameraPosition = .automatic
    @State private var pendingCoordinate: CLLocationCoordinate2D?
    @State private var pendingPlaceName = ""
    @State private var isShowingSaveSheet = false
    @State private var isShowingSavedPlaces = false
    @State private var selectedPlaceID: UUID?

    init(destinationName: String) {
        self.destinationName = destinationName
        _savedPlaces = Query(
            filter: #Predicate { place in
                place.destinationName == destinationName
            },
            sort: [SortDescriptor(\SavedPlace.createdAt, order: .reverse)]
        )
    }

    private var selectedPlace: SavedPlace? {
        savedPlaces.first { $0.id == selectedPlaceID }
    }

    var body: some View {
        MapReader { proxy in
            Map(position: $position) {
                ForEach(savedPlaces) { place in
                    Annotation(place.name, coordinate: coordinate(for: place), anchor: .bottom) {
                        savedPlaceAnnotation(for: place)
                    }
                }

                if let pendingCoordinate {
                    Annotation("New Place", coordinate: pendingCoordinate) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.red)
                            .accessibilityHidden(true)
                    }
                }
            }
            .accessibilityLabel("\(destinationName) map")
            .accessibilityHint("Long press to save a place or tap a saved pin to hear more details.")
            .gesture(longPressGesture(with: proxy))
            .sheet(isPresented: $isShowingSaveSheet) {
                savePlaceSheet
            }
            .sheet(isPresented: $isShowingSavedPlaces) {
                NavigationStack {
                    SavedPlacesListView(
                        destinationName: destinationName,
                        savedPlaces: savedPlaces,
                        onSelectPlace: selectSavedPlace
                    )
                }
            }
            .safeAreaInset(edge: .top) {
                CityHeaderView(destinationName: destinationName)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.regularMaterial)
            }
            .safeAreaInset(edge: .bottom) {
                if let selectedPlace {
                    selectedPlaceCard(for: selectedPlace)
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("\(destinationName) Map")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Saved") {
                        isShowingSavedPlaces = true
                    }
                    .accessibilityLabel("Saved places")
                    .accessibilityHint("Shows your saved places grouped by category.")
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedPlaceID)
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
                    .accessibilityLabel("Cancel saving place")
                    .accessibilityHint("Closes the save place sheet without adding a pin.")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        savePendingPlace()
                    }
                    .disabled(trimmedPendingName.isEmpty || pendingCoordinate == nil)
                    .accessibilityLabel("Save place")
                    .accessibilityHint("Adds this place to your saved map pins.")
                }
            }
        }
    }

    private func savedPlaceAnnotation(for place: SavedPlace) -> some View {
        Button {
            selectedPlaceID = place.id
        } label: {
            Image(systemName: place.id == selectedPlaceID ? "mappin.circle.fill" : "mappin.circle")
                .font(place.id == selectedPlaceID ? .title : .title2)
                .foregroundStyle(place.id == selectedPlaceID ? Color.accentColor : Color.red)
                .shadow(color: .black.opacity(0.16), radius: 6, y: 3)
                .padding(6)
                .background(.thinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(place.name), saved place")
        .accessibilityHint("Shows place details.")
    }

    private func selectedPlaceCard(for place: SavedPlace) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(place.name)
                    .font(.title3.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)

                Text(place.category?.displayName ?? "Other")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("Coordinates: \(formattedCoordinates(for: place))", systemImage: "location")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Label("Saved: \(formattedDate(for: place.createdAt))", systemImage: "calendar")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    openInMapsButton(for: place)
                    deleteButton(for: place)
                    closeButton
                }

                VStack(spacing: 10) {
                    openInMapsButton(for: place)
                    deleteButton(for: place)
                    closeButton
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08))
        )
        .shadow(color: .black.opacity(0.12), radius: 18, y: 8)
        .accessibilityElement(children: .contain)
    }

    private func openInMapsButton(for place: SavedPlace) -> some View {
        Button("Open in Maps") {
            openInMaps(for: place)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityLabel("Open \(place.name) in Maps")
        .accessibilityHint("Opens this location in the Maps app.")
    }

    private func deleteButton(for place: SavedPlace) -> some View {
        Button("Delete", role: .destructive) {
            delete(place)
        }
        .buttonStyle(.bordered)
        .accessibilityLabel("Delete \(place.name)")
        .accessibilityHint("Removes this saved place from the map.")
    }

    private var closeButton: some View {
        Button("Close") {
            selectedPlaceID = nil
        }
        .buttonStyle(.bordered)
        .accessibilityLabel("Close place details")
        .accessibilityHint("Hides the saved place details card.")
    }

    private var trimmedPendingName: String {
        pendingPlaceName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func coordinate(for place: SavedPlace) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
    }

    private func formattedCoordinates(for place: SavedPlace) -> String {
        "\(place.latitude.formatted(.number.precision(.fractionLength(4)))), \(place.longitude.formatted(.number.precision(.fractionLength(4))))"
    }

    private func formattedDate(for date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }

    private func longPressGesture(with proxy: MapProxy) -> some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
            .onEnded { value in
                guard case .second(true, let drag?) = value else { return }
                guard let coordinate = proxy.convert(drag.location, from: .local) else { return }

                selectedPlaceID = nil
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
                destinationName: destinationName,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                in: modelContext
            )
            clearPendingPlace()
        } catch {
            assertionFailure("Failed to save place: \(error.localizedDescription)")
        }
    }

    private func delete(_ place: SavedPlace) {
        do {
            try SavedPlaceService.deletePlace(place, in: modelContext)
            selectedPlaceID = nil
        } catch {
            assertionFailure("Failed to delete place: \(error.localizedDescription)")
        }
    }

    private func openInMaps(for place: SavedPlace) {
        let placemark = MKPlacemark(coordinate: coordinate(for: place))
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = place.name
        mapItem.openInMaps()
    }

    private func selectSavedPlace(_ place: SavedPlace) {
        selectedPlaceID = place.id
        isShowingSavedPlaces = false
        position = .region(
            MKCoordinateRegion(
                center: coordinate(for: place),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        )
    }

    private func clearPendingPlace() {
        pendingCoordinate = nil
        pendingPlaceName = ""
        isShowingSaveSheet = false
    }
}

#Preview {
    NavigationStack {
        MapHomeView(destinationName: "Paris")
    }
}
