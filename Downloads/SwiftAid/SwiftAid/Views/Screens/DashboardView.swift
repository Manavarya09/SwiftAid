//
//  DashboardView.swift
//  SwiftAid
//
//  Created by AI Assistant on 6/25/25.
//

import SwiftUI
import CoreLocation

struct DashboardView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var emergencyManager: EmergencyManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var healthManager: HealthManager

    @State private var showingEmergencyAlert = false
    @State private var showingProfile = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection

                    // Emergency Status
                    emergencyStatusSection

                    // Quick Actions
                    quickActionsSection

                    // Vital Signs
                    if healthManager.healthKitAuthorized {
                        vitalSignsSection
                    }

                    // Recent Events
                    recentEventsSection

                    // Emergency Services
                    emergencyServicesSection
                }
                .padding()
            }
            .background(GlassmorphicBackground().ignoresSafeArea())
            .navigationBarHidden(true)
            .refreshable {
                refreshData()
            }
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("SwiftAid")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Emergency ready")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: { showingProfile = true }) {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(.primary)
                    )
            }
        }
        .padding(.horizontal)
    }

    private var emergencyStatusSection: some View {
        GlassCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: emergencyManager.isMonitoring ? "shield.checkered" : "shield.slash")
                        .font(.title2)
                        .foregroundColor(emergencyManager.isMonitoring ? .green : .orange)

                    VStack(alignment: .leading) {
                        Text("Emergency Detection")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Text(emergencyManager.isMonitoring ? "Active and monitoring" : "Inactive")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { emergencyManager.isMonitoring },
                        set: { enabled in
                            if enabled {
                                emergencyManager.startMonitoring()
                            } else {
                                emergencyManager.stopMonitoring()
                            }
                        }
                    ))
                    .toggleStyle(SwitchToggleStyle(tint: .red))
                }

                if let emergency = emergencyManager.currentEmergency {
                    Divider()

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Active Emergency")
                                .font(.caption)
                                .foregroundColor(.red)

                            Text(emergency.type.rawValue.capitalized)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }

                        Spacer()

                        EmergencyStatusBadge(status: emergency.status)
                    }
                }
            }
            .padding()
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                EmergencyButton(
                    title: "Call 911",
                    icon: "phone.fill",
                    color: .red
                ) {
                    callEmergencyServices()
                }

                EmergencyButton(
                    title: "First Aid Guide",
                    icon: "cross.circle.fill",
                    color: .blue
                ) {
                    // Navigate to first aid
                }

                EmergencyButton(
                    title: "Share Location",
                    icon: "location.fill",
                    color: .green
                ) {
                    locationManager.shareLocationWithEmergencyServices()
                }

                EmergencyButton(
                    title: "Emergency Contacts",
                    icon: "person.2.fill",
                    color: .orange
                ) {
                    // Navigate to contacts
                }
            }
            .padding(.horizontal)
        }
    }

    private var vitalSignsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Vital Signs")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Text("Live")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    if let heartRate = healthManager.currentVitals.heartRate {
                        VitalsCard(
                            title: "Heart Rate",
                            value: "\(Int(heartRate))",
                            unit: "BPM",
                            icon: "heart.fill",
                            color: .red,
                            isNormal: heartRate >= 60 && heartRate <= 100
                        )
                    }

                    if let oxygen = healthManager.currentVitals.oxygenSaturation {
                        VitalsCard(
                            title: "Oxygen",
                            value: "\(Int(oxygen))",
                            unit: "%",
                            icon: "lungs.fill",
                            color: .blue,
                            isNormal: oxygen >= 95
                        )
                    }

                    if let temp = healthManager.currentVitals.temperature {
                        VitalsCard(
                            title: "Temperature",
                            value: String(format: "%.1f", temp),
                            unit: "°F",
                            icon: "thermometer",
                            color: .orange,
                            isNormal: temp >= 97.0 && temp <= 99.5
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var recentEventsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Events")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)

            if appViewModel.emergencyEvents.isEmpty {
                GlassCard {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.largeTitle)
                            .foregroundColor(.green)

                        Text("No Recent Emergencies")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Text("SwiftAid is monitoring and ready to help")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
                .padding(.horizontal)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(appViewModel.emergencyEvents.prefix(3))) { event in
                        EmergencyEventCard(event: event)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var emergencyServicesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nearby Emergency Services")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)

            if locationManager.nearbyEmergencyServices.isEmpty {
                GlassCard {
                    VStack(spacing: 12) {
                        Image(systemName: "location.slash")
                            .font(.largeTitle)
                            .foregroundColor(.orange)

                        Text("Location Required")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Text("Enable location services to find nearby emergency services")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button("Enable Location") {
                            locationManager.requestPermission()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding()
                }
                .padding(.horizontal)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(locationManager.nearbyEmergencyServices.prefix(3))) { service in
                        EmergencyServiceCard(service: service)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func callEmergencyServices() {
        if let url = URL(string: "tel://911") {
            UIApplication.shared.open(url)
        }
    }

    private func refreshData() {
        locationManager.findNearbyEmergencyServices()
        healthManager.requestPermission()
    }
}

struct EmergencyEventCard: View {
    let event: EmergencyEvent

    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                Image(systemName: event.type.icon)
                    .font(.title2)
                    .foregroundColor(Color(event.type.color))
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.type.rawValue.capitalized)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(event.description)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(event.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                EmergencyStatusBadge(status: event.status)
            }
            .padding()
        }
    }
}

struct EmergencyServiceCard: View {
    let service: EmergencyService

    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                Image(systemName: service.type.icon)
                    .font(.title2)
                    .foregroundColor(service.type.color)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(service.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text(service.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    Text("\(String(format: "%.1f", service.distance / 1000)) km away")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let phoneNumber = service.phoneNumber {
                    Button(action: {
                        if let url = URL(string: "tel://\(phoneNumber)") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Image(systemName: "phone.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
        }
    }
}
