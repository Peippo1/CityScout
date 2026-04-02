import SwiftUI
import SwiftData
import MapKit
import CoreLocation
import Combine

private struct SavedPlaceCategoryStyle {
    let icon: String
    let tint: Color
}

private struct ItineraryBadgeStyle {
    let text: String
    let tint: Color
    let backgroundOpacity: Double
}

private struct DestinationViewport {
    let center: CLLocationCoordinate2D
    let span: MKCoordinateSpan

    var region: MKCoordinateRegion {
        MKCoordinateRegion(center: center, span: span)
    }
}

private enum SavedPlaceViewportSupport {
    static func region(
        for coordinates: [CLLocationCoordinate2D],
        fallbackSpan: MKCoordinateSpan
    ) -> MKCoordinateRegion? {
        guard coordinates.isEmpty == false else { return nil }

        if coordinates.count == 1, let coordinate = coordinates.first {
            return MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: min(fallbackSpan.latitudeDelta, 0.04),
                    longitudeDelta: min(fallbackSpan.longitudeDelta, 0.04)
                )
            )
        }

        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)

        guard
            let minLatitude = latitudes.min(),
            let maxLatitude = latitudes.max(),
            let minLongitude = longitudes.min(),
            let maxLongitude = longitudes.max()
        else {
            return nil
        }

        let latitudeDelta = max((maxLatitude - minLatitude) * 1.45, 0.03)
        let longitudeDelta = max((maxLongitude - minLongitude) * 1.45, 0.03)

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLatitude + maxLatitude) / 2,
                longitude: (minLongitude + maxLongitude) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max(latitudeDelta, fallbackSpan.latitudeDelta * 0.35),
                longitudeDelta: max(longitudeDelta, fallbackSpan.longitudeDelta * 0.35)
            )
        )
    }
}

@MainActor
private final class MapLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var currentLocation: CLLocation?

    private let manager = CLLocationManager()

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    func requestCurrentLocation() {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            break
        @unknown default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Ignore failures and let the UI fall back to destination-centred controls.
    }
}

struct MapHomeView: View {
    private enum MapFilterMode: String, CaseIterable, Identifiable {
        case all
        case itinerary

        var id: String { rawValue }
    }

    let destinationName: String

    @Environment(\.modelContext) private var modelContext

    @Query
    private var savedPlaces: [SavedPlace]

    @State private var position: MapCameraPosition
    @State private var pendingCoordinate: CLLocationCoordinate2D?
    @State private var pendingPlaceName = ""
    @State private var isShowingSaveSheet = false
    @State private var isShowingSavedPlaces = false
    @State private var selectedPlaceID: UUID?
    @State private var filterMode: MapFilterMode = .all
    @State private var isShowingRoute = true
    @State private var hasCenteredOnDestination = false
    @StateObject private var locationManager = MapLocationManager()

    init(destinationName: String) {
        self.destinationName = destinationName
        if let initialViewport = Self.viewport(for: destinationName) {
            _position = State(initialValue: .region(initialViewport.region))
        } else {
            _position = State(initialValue: .automatic)
        }
        _savedPlaces = Query(
            filter: #Predicate { place in
                place.destinationName == destinationName
            },
            sort: [SortDescriptor(\SavedPlace.createdAt, order: .reverse)]
        )
    }

    private var selectedPlace: SavedPlace? {
        filteredSavedPlaces.first { $0.id == selectedPlaceID }
    }

    private var filteredSavedPlaces: [SavedPlace] {
        switch filterMode {
        case .all:
            return savedPlaces
        case .itinerary:
            return savedPlaces.filter(\.isItineraryDerived)
        }
    }

    private var itineraryPlaces: [SavedPlace] {
        savedPlaces.filter(\.isItineraryDerived)
    }

    private var mappableFilteredSavedPlaces: [SavedPlace] {
        filteredSavedPlaces.filter(\.hasUsableMapCoordinate)
    }

    private var validItineraryRoutePlaces: [SavedPlace] {
        itineraryPlaces.filter(\.hasUsableMapCoordinate)
    }

    private var itineraryRouteCoordinates: [CLLocationCoordinate2D] {
        validItineraryRoutePlaces.map(coordinate(for:))
    }

    private var unmatchedItineraryPlaces: [SavedPlace] {
        itineraryPlaces.filter(\.isUnmatchedItineraryPlace)
    }

    private var itineraryMappingHint: String? {
        guard filterMode == .itinerary, unmatchedItineraryPlaces.isEmpty == false else {
            return nil
        }

        if validItineraryRoutePlaces.isEmpty {
            return unmatchedItineraryPlaces.count == 1
            ? "1 itinerary place is saved without map coordinates yet."
            : "\(unmatchedItineraryPlaces.count) itinerary places are saved without map coordinates yet."
        }

        return unmatchedItineraryPlaces.count == 1
        ? "Route and centering use matched stops. 1 itinerary place is still generic."
        : "Route and centering use matched stops. \(unmatchedItineraryPlaces.count) itinerary places are still generic."
    }

    private var shouldShowItineraryEmptyState: Bool {
        filterMode == .itinerary && itineraryPlaces.isEmpty
    }

    private var shouldDrawItineraryRoute: Bool {
        filterMode == .itinerary && isShowingRoute && itineraryRouteCoordinates.count >= 2
    }

    private var shouldShowRouteEmptyState: Bool {
        filterMode == .itinerary
        && shouldShowItineraryEmptyState == false
        && validItineraryRoutePlaces.count < 2
    }

    private var destinationViewport: DestinationViewport? {
        Self.viewport(for: destinationName)
    }

    private var userLocationAvailable: Bool {
        locationManager.currentLocation != nil
    }

    var body: some View {
        MapReader { proxy in
            Map(position: $position) {
                if shouldDrawItineraryRoute {
                    MapPolyline(coordinates: itineraryRouteCoordinates)
                        .stroke(Color.brandSage, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                    // TODO: replace this straight-line path with route optimization when mapped itinerary data is richer.
                }

                ForEach(mappableFilteredSavedPlaces) { place in
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
                        savedPlaces: filteredSavedPlaces,
                        onSelectPlace: selectSavedPlace
                    )
                }
            }
            .safeAreaInset(edge: .top) {
                VStack(alignment: .leading, spacing: 12) {
                    CityHeaderView(destinationName: destinationName)

                    Picker("Map filter", selection: $filterMode) {
                        Text("All")
                            .tag(MapFilterMode.all)
                            .accessibilityLabel("Show all places")
                        Text("Itinerary")
                            .tag(MapFilterMode.itinerary)
                            .accessibilityLabel("Show itinerary places only")
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Map filter")
                    .accessibilityValue(
                        filterMode == .all ? "Show all places" : "Show itinerary places only"
                    )

                    if filterMode == .itinerary {
                        Toggle("Show Route", isOn: $isShowingRoute)
                            .toggleStyle(.switch)
                            .accessibilityLabel("Show Route")
                            .accessibilityValue(isShowingRoute ? "On" : "Off")
                    }

                    if let itineraryMappingHint {
                        Label(itineraryMappingHint, systemImage: "info.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: 10) {
                        Button("My Location") {
                            centerOnUserLocation()
                        }
                        .buttonStyle(.bordered)
                        .tint(userLocationAvailable ? .brandGreenDark : .brandSage)
                        .accessibilityLabel("Show my location")
                        .accessibilityHint("Requests your current location and centers the map there when available.")

                        Button("City") {
                            centerOnDestination()
                        }
                        .buttonStyle(.bordered)
                        .tint(.brandSage)
                        .accessibilityLabel("Show selected city")
                        .accessibilityHint("Re-centers the map on \(destinationName).")

                        Spacer()
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    Color.brandCream.opacity(0.92)
                        .shadow(color: Color.brandGreenDark.opacity(0.08), radius: 10, y: 4)
                )
            }
            .safeAreaInset(edge: .bottom) {
                if let selectedPlace {
                    selectedPlaceCard(for: selectedPlace)
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    EmptyView()
                }
            }
            .overlay {
                if shouldShowItineraryEmptyState {
                    ContentUnavailableView(
                        "No itinerary places yet",
                        systemImage: "map",
                        description: Text("Generate a plan to see your day on the map")
                    )
                    .padding()
                    .background(Color.brandCream.opacity(0.94), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding()
                } else if shouldShowRouteEmptyState {
                    ContentUnavailableView(
                        "Not enough mapped itinerary stops yet",
                        systemImage: "point.topleft.down.curvedto.point.bottomright.up",
                        description: Text("The map only routes across matched itinerary places with real coordinates.")
                    )
                    .padding()
                    .background(Color.brandCream.opacity(0.94), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding()
                } else {
                    EmptyView()
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
            .animation(.easeInOut(duration: 0.2), value: filterMode)
            .animation(.easeInOut(duration: 0.2), value: isShowingRoute)
            .task {
                guard hasCenteredOnDestination == false else { return }
                centerOnBestAvailableContent()
                hasCenteredOnDestination = true
            }
            .onChange(of: destinationName) { _, _ in
                hasCenteredOnDestination = false
                centerOnBestAvailableContent()
                hasCenteredOnDestination = true
            }
            .onChange(of: filterMode) { _, _ in
                if let selectedPlaceID,
                   filteredSavedPlaces.contains(where: { $0.id == selectedPlaceID }) == false {
                    self.selectedPlaceID = nil
                }

                centerOnBestAvailableContent()
            }
            .onChange(of: locationManager.currentLocation) { _, location in
                guard let location else { return }
                position = .region(
                    MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    )
                )
            }
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
        let style = categoryStyle(for: place.category)
        let isSelected = place.id == selectedPlaceID
        let isItineraryFocusMode = filterMode == .itinerary && place.isItineraryDerived
        let pinDiameter: CGFloat = isSelected ? 34 : 30
        let ringDiameter: CGFloat = isSelected ? 42 : 38

        return Button {
            selectedPlaceID = place.id
        } label: {
            ZStack {
                Circle()
                    .fill(annotationFillColor(for: place, baseTint: style.tint))
                    .frame(width: pinDiameter, height: pinDiameter)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.9), lineWidth: 2)
                    )

                if place.isMappedItineraryPlace {
                    Circle()
                        .stroke(style.tint.opacity(0.95), lineWidth: 2.5)
                        .frame(width: ringDiameter, height: ringDiameter)
                } else if place.isUnmatchedItineraryPlace {
                    Circle()
                        .stroke(style.tint.opacity(0.9), style: StrokeStyle(lineWidth: 2, dash: [3, 2]))
                        .frame(width: ringDiameter, height: ringDiameter)
                }

                Image(systemName: style.icon)
                    .font(isSelected ? .headline : .subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                if place.isMappedItineraryPlace {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(style.tint, .white)
                        .background(.thinMaterial, in: Circle())
                        .offset(x: ringDiameter / 3.2, y: -ringDiameter / 3.2)
                } else if place.isUnmatchedItineraryPlace {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.orange, .white)
                        .background(.thinMaterial, in: Circle())
                        .offset(x: ringDiameter / 3.2, y: -ringDiameter / 3.2)
                }
            }
            .scaleEffect(isItineraryFocusMode ? 1.16 : (isSelected ? 1.12 : 1.0))
            .opacity(place.isUnmatchedItineraryPlace ? 0.78 : 1)
            .shadow(color: .black.opacity(place.isUnmatchedItineraryPlace ? 0.1 : 0.16), radius: 6, y: 3)
            .padding(6)
            .background(.thinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(annotationAccessibilityLabel(for: place))
        .accessibilityHint("Shows place details.")
    }

    private func selectedPlaceCard(for place: SavedPlace) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(place.name)
                    .font(.title3.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Text(place.category?.displayName ?? "Other")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let badgeStyle = itineraryBadgeStyle(for: place) {
                        Text(badgeStyle.text)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                badgeStyle.tint.opacity(badgeStyle.backgroundOpacity),
                                in: Capsule(style: .continuous)
                            )
                            .foregroundStyle(badgeStyle.tint)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                if let itineraryStatusText = place.itineraryStatusText {
                    Label(itineraryStatusText, systemImage: place.isMappedItineraryPlace ? "checkmark.circle.fill" : "questionmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(place.isMappedItineraryPlace ? Color.brandGreenDark : .orange)
                }

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
                .fill(Color.brandCream.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.brandSage.opacity(0.18))
        )
        .shadow(color: Color.brandGreenDark.opacity(0.12), radius: 18, y: 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(detailCardAccessibilityLabel(for: place))
    }

    private func openInMapsButton(for place: SavedPlace) -> some View {
        Button("Open in Maps") {
            openInMaps(for: place)
        }
        .buttonStyle(.borderedProminent)
        .tint(.brandGreenDark)
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
        .tint(.brandSage)
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

    private func annotationAccessibilityLabel(for place: SavedPlace) -> String {
        let categoryName = place.category?.displayName.lowercased() ?? "other"
        if let itineraryState = place.itineraryAccessibilityState {
            return "\(place.name), \(categoryName), \(itineraryState), \(place.destinationName)"
        }
        return "\(place.name), \(categoryName), \(place.destinationName)"
    }

    private func detailCardAccessibilityLabel(for place: SavedPlace) -> String {
        let categoryName = place.category?.displayName.lowercased() ?? "other"
        if let itineraryState = place.itineraryAccessibilityState {
            return "\(place.name), \(categoryName), \(itineraryState), \(place.destinationName)"
        }
        return "\(place.name), \(categoryName), \(place.destinationName)"
    }

    private func annotationFillColor(for place: SavedPlace, baseTint: Color) -> Color {
        if place.isUnmatchedItineraryPlace {
            return baseTint.opacity(0.58)
        }

        return baseTint
    }

    private func itineraryBadgeStyle(for place: SavedPlace) -> ItineraryBadgeStyle? {
        if place.isMappedItineraryPlace {
            return ItineraryBadgeStyle(
                text: "From itinerary • Mapped",
                tint: .brandGreenDark,
                backgroundOpacity: 0.14
            )
        }

        if place.isUnmatchedItineraryPlace {
            return ItineraryBadgeStyle(
                text: "From itinerary • Not mapped yet",
                tint: .orange,
                backgroundOpacity: 0.16
            )
        }

        if place.isItineraryDerived {
            return ItineraryBadgeStyle(
                text: "From itinerary",
                tint: .brandSage,
                backgroundOpacity: 0.14
            )
        }

        return nil
    }

    private func categoryStyle(for category: POICategory?) -> SavedPlaceCategoryStyle {
        switch category {
        case .food:
            return SavedPlaceCategoryStyle(icon: "fork.knife", tint: .orange)
        case .cafes:
            return SavedPlaceCategoryStyle(icon: "cup.and.saucer.fill", tint: .brown)
        case .sights:
            return SavedPlaceCategoryStyle(icon: "camera.fill", tint: .blue)
        case .shopping:
            return SavedPlaceCategoryStyle(icon: "bag.fill", tint: .pink)
        case .nightlife:
            return SavedPlaceCategoryStyle(icon: "moon.stars.fill", tint: .purple)
        case nil:
            return SavedPlaceCategoryStyle(icon: "mappin.circle.fill", tint: .red)
        }
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
                source: SavedPlace.Source.manual.rawValue,
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
        // TODO: update deprecated MKPlacemark API for newer iOS SDK
        let placemark = MKPlacemark(coordinate: coordinate(for: place))
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = place.name
        mapItem.openInMaps()
    }

    private func selectSavedPlace(_ place: SavedPlace) {
        selectedPlaceID = place.id
        isShowingSavedPlaces = false

        guard place.hasUsableMapCoordinate else {
            centerOnBestAvailableContent()
            return
        }

        position = .region(
            MKCoordinateRegion(
                center: coordinate(for: place),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        )
    }

    private func centerOnDestination() {
        guard let destinationViewport else { return }
        selectedPlaceID = nil
        position = .region(destinationViewport.region)
    }

    private func centerOnBestAvailableContent() {
        let focusPlaces: [SavedPlace]
        switch filterMode {
        case .all:
            focusPlaces = mappableFilteredSavedPlaces
        case .itinerary:
            focusPlaces = validItineraryRoutePlaces
        }

        if
            let fallbackSpan = destinationViewport?.span ?? MKCoordinateSpan(latitudeDelta: 0.18, longitudeDelta: 0.18),
            let region = SavedPlaceViewportSupport.region(
                for: focusPlaces.map(coordinate(for:)),
                fallbackSpan: fallbackSpan
            )
        {
            selectedPlaceID = nil
            position = .region(region)
            return
        }

        centerOnDestination()
    }

    private func centerOnUserLocation() {
        if let location = locationManager.currentLocation {
            selectedPlaceID = nil
            position = .region(
                MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            )
            return
        }

        locationManager.requestCurrentLocation()
    }

    private static func viewport(for destinationName: String) -> DestinationViewport? {
        switch destinationName {
        case "Amsterdam":
            return DestinationViewport(center: CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041), span: MKCoordinateSpan(latitudeDelta: 0.18, longitudeDelta: 0.18))
        case "Athens":
            return DestinationViewport(center: CLLocationCoordinate2D(latitude: 37.9838, longitude: 23.7275), span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
        case "Barcelona":
            return DestinationViewport(center: CLLocationCoordinate2D(latitude: 41.3874, longitude: 2.1686), span: MKCoordinateSpan(latitudeDelta: 0.18, longitudeDelta: 0.18))
        case "Berlin":
            return DestinationViewport(center: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050), span: MKCoordinateSpan(latitudeDelta: 0.24, longitudeDelta: 0.24))
        case "Brussels":
            return DestinationViewport(center: CLLocationCoordinate2D(latitude: 50.8503, longitude: 4.3517), span: MKCoordinateSpan(latitudeDelta: 0.16, longitudeDelta: 0.16))
        case "Budapest":
            return DestinationViewport(center: CLLocationCoordinate2D(latitude: 47.4979, longitude: 19.0402), span: MKCoordinateSpan(latitudeDelta: 0.18, longitudeDelta: 0.18))
        case "Copenhagen":
            return DestinationViewport(center: CLLocationCoordinate2D(latitude: 55.6761, longitude: 12.5683), span: MKCoordinateSpan(latitudeDelta: 0.18, longitudeDelta: 0.18))
        case "Dublin":
            return DestinationViewport(center: CLLocationCoordinate2D(latitude: 53.3498, longitude: -6.2603), span: MKCoordinateSpan(latitudeDelta: 0.18, longitudeDelta: 0.18))
        case "Helsinki":
            return DestinationViewport(center: CLLocationCoordinate2D(latitude: 60.1699, longitude: 24.9384), span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
        case "Lisbon":
            return DestinationViewport(center: CLLocationCoordinate2D(latitude: 38.7223, longitude: -9.1393), span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
        case "Oslo":
            return DestinationViewport(center: CLLocationCoordinate2D(latitude: 59.9139, longitude: 10.7522), span: MKCoordinateSpan(latitudeDelta: 0.18, longitudeDelta: 0.18))
        case "Paris":
            return DestinationViewport(center: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522), span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
        case "Prague":
            return DestinationViewport(center: CLLocationCoordinate2D(latitude: 50.0755, longitude: 14.4378), span: MKCoordinateSpan(latitudeDelta: 0.16, longitudeDelta: 0.16))
        case "Rome":
            return DestinationViewport(center: CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964), span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
        case "Stockholm":
            return DestinationViewport(center: CLLocationCoordinate2D(latitude: 59.3293, longitude: 18.0686), span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
        case "Vienna":
            return DestinationViewport(center: CLLocationCoordinate2D(latitude: 48.2082, longitude: 16.3738), span: MKCoordinateSpan(latitudeDelta: 0.18, longitudeDelta: 0.18))
        case "Warsaw":
            return DestinationViewport(center: CLLocationCoordinate2D(latitude: 52.2297, longitude: 21.0122), span: MKCoordinateSpan(latitudeDelta: 0.18, longitudeDelta: 0.18))
        default:
            return nil
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
        MapHomeView(destinationName: "Paris")
    }
}
