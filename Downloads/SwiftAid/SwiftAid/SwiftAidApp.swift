//
//  SwiftAidApp.swift
//  SwiftAid
//
//  Created by AI Assistant on 6/25/25.
//

import SwiftUI
import Firebase
import UserNotifications
import CoreLocation
import HealthKit

@main
struct SwiftAidApp: App {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var emergencyManager = EmergencyManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var healthManager = HealthManager()
    @StateObject private var notificationManager = NotificationManager()

    init() {
        // Configure Firebase
        FirebaseApp.configure()

        // Setup app appearance
        setupAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appViewModel)
                .environmentObject(emergencyManager)
                .environmentObject(locationManager)
                .environmentObject(healthManager)
                .environmentObject(notificationManager)
                .onAppear {
                    setupApp()
                }
        }
    }

    private func setupApp() {
        // Request permissions
        notificationManager.requestPermission()
        locationManager.requestPermission()
        healthManager.requestPermission()

        // Setup emergency detection
        emergencyManager.startMonitoring()
    }

    private func setupAppearance() {
        // Custom appearance setup for glassmorphism
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.clear
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}
