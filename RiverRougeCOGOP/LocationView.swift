import SwiftUI
import MapKit

// Custom struct for map annotation that conforms to Identifiable
struct ChurchAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct LocationView: View {
    @Environment(\.dismiss) var dismiss
    let address = "41 Orchard St, River Rouge, MI 48218"
    @State private var region = MKCoordinateRegion()
    @State private var churchAnnotation: ChurchAnnotation?
    @State private var userLocation: CLLocationCoordinate2D?
    @State private var route: MKRoute?
    @State private var showingRoute = false
    @State private var routeError: String?
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 20) {
                    // Header
                    Text("Church Location")
                        .font(.title)
                        .foregroundColor(.white)
                        .bold()
                        .padding(.top)

                    // Map View
                    MapViewWithOverlay(region: $region, churchAnnotation: churchAnnotation, route: route, showingRoute: showingRoute)
                        .frame(height: 300)
                        .cornerRadius(15)
                        .shadow(radius: 10)

                    // Address Details
                    VStack(alignment: .leading, spacing: 10) {
                        Text(address)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                        Text("Bishop Leonard Clarke")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.6))
                    .cornerRadius(15)
                    .shadow(radius: 5)

                    // Navigation Button
                    Button(action: {
                        if let userLoc = locationManager.userLocation, let churchLoc = churchAnnotation?.coordinate {
                            calculateRoute(from: userLoc, to: churchLoc)
                            showingRoute = true
                        } else if let churchLoc = churchAnnotation?.coordinate {
                            let fallbackLocation = CLLocationCoordinate2D(latitude: 42.2745, longitude: -83.1307) // Near River Rouge
                            calculateRoute(from: fallbackLocation, to: churchLoc)
                            showingRoute = true
                        } else {
                            routeError = "Unable to determine locations."
                        }
                    }) {
                        Text("Show Route")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    .disabled(churchAnnotation == nil)
                    .padding(.horizontal)

                    // Error Message
                    if let errorMessage = routeError {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    Spacer()

                    // Close Button
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Close")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    .padding(.bottom)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                updateRegion()
                locationManager.requestLocation()
            }
            .onReceive(locationManager.$userLocation) { newLocation in
                if let userLoc = newLocation, let churchLoc = churchAnnotation?.coordinate {
                    updateRegionWithUserAndChurch(userLocation: userLoc, churchLocation: churchLoc)
                }
            }
        }
    }

    private func updateRegion() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let placemark = placemarks?.first, let location = placemark.location {
                let coordinate = location.coordinate
                churchAnnotation = ChurchAnnotation(coordinate: coordinate)
                region = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
                if let userLoc = locationManager.userLocation {
                    updateRegionWithUserAndChurch(userLocation: userLoc, churchLocation: coordinate)
                }
            } else {
                routeError = "Failed to geocode church address: \(error?.localizedDescription ?? "Unknown error")"
            }
        }
    }

    private func updateRegionWithUserAndChurch(userLocation: CLLocationCoordinate2D, churchLocation: CLLocationCoordinate2D) {
        let minLat = min(userLocation.latitude, churchLocation.latitude)
        let maxLat = max(userLocation.latitude, churchLocation.latitude)
        let minLon = min(userLocation.longitude, churchLocation.longitude)
        let maxLon = max(userLocation.longitude, churchLocation.longitude)

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.4, 0.02),
            longitudeDelta: max((maxLon - minLon) * 1.4, 0.02)
        )

        region = MKCoordinateRegion(center: center, span: span)
    }

    private func calculateRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            DispatchQueue.main.async {
                if let route = response?.routes.first {
                    self.route = route
                    if let userLoc = locationManager.userLocation {
                        updateRegionWithUserAndChurch(userLocation: userLoc, churchLocation: destination)
                    } else {
                        updateRegionWithUserAndChurch(userLocation: source, churchLocation: destination)
                    }
                } else {
                    routeError = "Route calculation failed: \(error?.localizedDescription ?? "Unknown error")"
                }
            }
        }
    }
}

// Location Manager to handle user location
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first?.coordinate {
            userLocation = location
            locationManager.stopUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error.localizedDescription)")
    }
}

// UIViewRepresentable for MKMapView with annotations and route overlay
struct MapViewWithOverlay: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var churchAnnotation: ChurchAnnotation?
    var route: MKRoute?
    var showingRoute: Bool

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)

        // Remove existing annotations and overlays to avoid duplication
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)

        // Add church annotation
        if let church = churchAnnotation {
            let annotation = MKPointAnnotation()
            annotation.coordinate = church.coordinate
            mapView.addAnnotation(annotation)
        }

        // Add route overlay if showing route
        if let route = route, showingRoute {
            mapView.addOverlay(route.polyline)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewWithOverlay

        init(_ parent: MapViewWithOverlay) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil // Use default user location view
            }
            let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "church")
            view.markerTintColor = .red
            return view
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 3
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

struct LocationView_Previews: PreviewProvider {
    static var previews: some View {
        LocationView()
            .preferredColorScheme(.dark)
    }
}
