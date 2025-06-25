//
//  EmergencyMapView.swift
//  SwiftAid
//
//  Created by AI Assistant on 6/25/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct EmergencyMapView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var emergencyManager: EmergencyManager

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    @State private var showingServiceDetails = false
    @State private var selectedService: EmergencyService?
    @State private var mapType: MapType = .standard

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Map
                Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: locationManager.nearbyEmergencyServices) { service in
                    MapAnnotation(coordinate: service.coordinate) {
                        EmergencyServiceAnnotation(service: service) {
                            selectedService = service
                            showingServiceDetails = true
                        }
                    }
                }
                .mapStyle(mapType.mapStyle)
                .ignoresSafeArea()

                // Top controls
                VStack {
                    HStack {
                        // Map type selector
                        GlassCard {
                            HStack(spacing: 16) {
                                ForEach(MapType.allCases, id: \.self) { type in
                                    Button(action: { mapType = type }) {
                                        Image(systemName: type.icon)
                                            .font(.title3)
                                            .foregroundColor(mapType == type ? .white : .primary)
                                            .padding(8)
                                            .background(
                                                Circle()
                                                    .fill(mapType == type ? Color.blue : Color.clear)
                                            )
                                    }
                                }
                            }
                            .padding(8)
                        }

                        Spacer()

                        // Emergency SOS button
                        Button(action: triggerEmergencySOS) {
                            ZStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 60, height: 60)
                                    .shadow(color: .red.opacity(0.4), radius: 10)

                                Text("SOS")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        .emergencyGlow()
                    }
                    .padding()

                    Spacer()
                }

                // Bottom sheet
                VStack {
                    Spacer()

                    GlassCard {
                        VStack(spacing: 16) {
                            // Handle
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.secondary)
                                .frame(width: 40, height: 4)

                            // Location info
                            if let location = locationManager.location {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Current Location")
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        Text(locationManager.currentAddress.isEmpty ? "Locating..." : locationManager.currentAddress)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .lineLimit(2)
                                    }

                                    Spacer()

                                    Button(action: {
                                        locationManager.shareLocationWithEmergencyServices()
                                    }) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.title2)
                                            .foregroundColor(.blue)
                                    }
                                }
                            }

                            Divider()

                            // Emergency services list
                            HStack {
                                Text("Nearby Emergency Services")
                                    .font(.headline)
                                    .fontWeight(.semibold)

                                Spacer()

                                Text("\(locationManager.nearbyEmergencyServices.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            if locationManager.nearbyEmergencyServices.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.largeTitle)
                                        .foregroundColor(.secondary)

                                    Text("Searching for emergency services...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            } else {
                                LazyVStack(spacing: 8) {
                                    ForEach(Array(locationManager.nearbyEmergencyServices.prefix(3))) { service in
                                        EmergencyServiceRow(service: service) {
                                            selectedService = service
                                            showingServiceDetails = true
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Emergency Map")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                updateMapRegion()
            }
            .onChange(of: locationManager.location) { _ in
                updateMapRegion()
            }
        }
        .sheet(item: $selectedService) { service in
            EmergencyServiceDetailView(service: service)
        }
    }

    private func updateMapRegion() {
        if let location = locationManager.location {
            withAnimation(.easeInOut(duration: 1.0)) {
                region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
        }
    }

    private func triggerEmergencySOS() {
        let emergency = EmergencyEvent(
            type: .medical,
            timestamp: Date(),
            location: locationManager.location?.coordinate,
            description: "Manual SOS triggered from map",
            severity: .high,
            status: .confirmed
        )

        emergencyManager.triggerEmergency(emergency)
    }
}

enum MapType: CaseIterable {
    case standard
    case satellite
    case hybrid

    var icon: String {
        switch self {
        case .standard: return "map"
        case .satellite: return "globe.americas"
        case .hybrid: return "map.fill"
        }
    }

    var mapStyle: MapStyle {
        switch self {
        case .standard: return .standard
        case .satellite: return .imagery
        case .hybrid: return .hybrid
        }
    }
}

struct EmergencyServiceAnnotation: View {
    let service: EmergencyService
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(service.type.color.opacity(0.3))
                    .frame(width: 40, height: 40)

                Circle()
                    .fill(service.type.color)
                    .frame(width: 24, height: 24)

                Image(systemName: service.type.icon)
                    .font(.caption)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
            }
        }
        .shadow(color: service.type.color.opacity(0.4), radius: 5)
    }
}

struct EmergencyServiceRow: View {
    let service: EmergencyService
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: service.type.icon)
                    .font(.title3)
                    .foregroundColor(service.type.color)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(service.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text("\(String(format: "%.1f", service.distance / 1000)) km away")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmergencyServiceDetailView: View {
    let service: EmergencyService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(service.type.color.opacity(0.2))
                            .frame(width: 80, height: 80)

                        Image(systemName: service.type.icon)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(service.type.color)
                    }

                    VStack(spacing: 8) {
                        Text(service.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text(service.address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Text("\(String(format: "%.1f", service.distance / 1000)) km away")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Actions
                VStack(spacing: 16) {
                    if let phoneNumber = service.phoneNumber {
                        Button(action: {
                            if let url = URL(string: "tel://\(phoneNumber)") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "phone.fill")
                                    .font(.title3)

                                Text("Call \(phoneNumber)")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                        }
                    }

                    Button(action: {
                        openMapsDirections()
                    }) {
                        HStack {
                            Image(systemName: "location.fill")
                                .font(.title3)

                            Text("Get Directions")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Emergency Service")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
    }

    private func openMapsDirections() {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: service.coordinate))
        mapItem.name = service.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}
