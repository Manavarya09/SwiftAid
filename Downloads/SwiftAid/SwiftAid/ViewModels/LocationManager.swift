//
//  LocationManager.swift
//  SwiftAid
//
//  Created by AI Assistant on 6/25/25.
//

import SwiftUI
import Combine
import CoreLocation
import MapKit

class LocationManager: NSObject, ObservableObject {
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var nearbyEmergencyServices: [EmergencyService] = []
    @Published var currentAddress: String = ""
    @Published var isLocationEnabled = false

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        setupLocationManager()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10.0
    }

    func requestPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .denied, .restricted:
            // Guide user to settings
            break
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }

    func startLocationUpdates() {
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            return
        }

        isLocationEnabled = true
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
    }

    func stopLocationUpdates() {
        isLocationEnabled = false
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
    }

    func getCurrentLocationString() -> String {
        guard let location = location else { return "Location unavailable" }

        return "Lat: \(String(format: "%.6f", location.coordinate.latitude)), " +
               "Lon: \(String(format: "%.6f", location.coordinate.longitude))"
    }

    func shareLocationWithEmergencyServices() {
        guard let location = location else { return }

        // Share location with emergency services
        let locationString = getCurrentLocationString()
        let shareText = "Emergency location: \(locationString)\nAddress: \(currentAddress)"

        DispatchQueue.main.async {
            let activityVC = UIActivityViewController(
                activityItems: [shareText],
                applicationActivities: nil
            )

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(activityVC, animated: true)
            }
        }
    }

    private func reverseGeocode(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self, let placemark = placemarks?.first else { return }

            DispatchQueue.main.async {
                self.currentAddress = self.formatAddress(from: placemark)
            }
        }
    }

    private func formatAddress(from placemark: CLPlacemark) -> String {
        var addressComponents: [String] = []

        if let streetNumber = placemark.subThoroughfare {
            addressComponents.append(streetNumber)
        }
        if let streetName = placemark.thoroughfare {
            addressComponents.append(streetName)
        }
        if let city = placemark.locality {
            addressComponents.append(city)
        }
        if let state = placemark.administrativeArea {
            addressComponents.append(state)
        }
        if let zipCode = placemark.postalCode {
            addressComponents.append(zipCode)
        }

        return addressComponents.joined(separator: ", ")
    }

    func findNearbyEmergencyServices() {
        guard let location = location else { return }

        let searchTypes = ["hospital", "fire station", "police station"]

        for searchType in searchTypes {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = searchType
            request.region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 10000,
                longitudinalMeters: 10000
            )

            let search = MKLocalSearch(request: request)
            search.start { [weak self] response, error in
                guard let self = self, let response = response else { return }

                let services = response.mapItems.map { item in
                    EmergencyService(
                        name: item.name ?? "Unknown",
                        type: self.serviceType(from: searchType),
                        coordinate: item.placemark.coordinate,
                        address: self.formatAddress(from: item.placemark),
                        phoneNumber: item.phoneNumber,
                        distance: item.placemark.location?.distance(from: location) ?? 0
                    )
                }

                DispatchQueue.main.async {
                    self.nearbyEmergencyServices.append(contentsOf: services)
                    self.nearbyEmergencyServices.sort { $0.distance < $1.distance }
                }
            }
        }
    }

    private func serviceType(from searchType: String) -> EmergencyServiceType {
        switch searchType.lowercased() {
        case "hospital": return .hospital
        case "fire station": return .fireStation
        case "police station": return .policeStation
        default: return .hospital
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        location = newLocation
        reverseGeocode(newLocation)
        findNearbyEmergencyServices()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status

            switch status {
            case .authorizedAlways, .authorizedWhenInUse:
                self.startLocationUpdates()
            case .denied, .restricted:
                self.stopLocationUpdates()
            default:
                break
            }
        }
    }
}

// MARK: - Emergency Service Model
struct EmergencyService: Identifiable {
    let id = UUID()
    let name: String
    let type: EmergencyServiceType
    let coordinate: CLLocationCoordinate2D
    let address: String
    let phoneNumber: String?
    let distance: CLLocationDistance
}

enum EmergencyServiceType {
    case hospital
    case fireStation
    case policeStation

    var icon: String {
        switch self {
        case .hospital: return "cross.fill"
        case .fireStation: return "flame.fill"
        case .policeStation: return "shield.fill"
        }
    }

    var color: Color {
        switch self {
        case .hospital: return .red
        case .fireStation: return .orange
        case .policeStation: return .blue
        }
    }
}
