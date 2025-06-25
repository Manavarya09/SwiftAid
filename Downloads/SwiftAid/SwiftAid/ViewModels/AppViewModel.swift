//
//  AppViewModel.swift
//  SwiftAid
//
//  Created by AI Assistant on 6/25/25.
//

import SwiftUI
import Combine
import Foundation

class AppViewModel: ObservableObject {
    @Published var isOnboardingComplete = false
    @Published var currentUser: UserProfile = UserProfile()
    @Published var emergencyEvents: [EmergencyEvent] = []
    @Published var isEmergencyMode = false
    @Published var showingEmergencyAlert = false
    @Published var currentTheme: AppTheme = .dark
    @Published var isOfflineMode = false

    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard

    init() {
        loadUserProfile()
        loadEmergencyEvents()
        checkOnboardingStatus()
    }

    // MARK: - User Profile Management
    func saveUserProfile() {
        if let encoded = try? JSONEncoder().encode(currentUser) {
            userDefaults.set(encoded, forKey: "userProfile")
        }
    }

    private func loadUserProfile() {
        if let data = userDefaults.data(forKey: "userProfile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            currentUser = profile
        }
    }

    // MARK: - Emergency Events Management
    func addEmergencyEvent(_ event: EmergencyEvent) {
        emergencyEvents.insert(event, at: 0)
        saveEmergencyEvents()
    }

    func updateEmergencyEvent(_ event: EmergencyEvent) {
        if let index = emergencyEvents.firstIndex(where: { $0.id == event.id }) {
            emergencyEvents[index] = event
            saveEmergencyEvents()
        }
    }

    private func saveEmergencyEvents() {
        if let encoded = try? JSONEncoder().encode(emergencyEvents) {
            userDefaults.set(encoded, forKey: "emergencyEvents")
        }
    }

    private func loadEmergencyEvents() {
        if let data = userDefaults.data(forKey: "emergencyEvents"),
           let events = try? JSONDecoder().decode([EmergencyEvent].self, from: data) {
            emergencyEvents = events
        }
    }

    // MARK: - Onboarding
    private func checkOnboardingStatus() {
        isOnboardingComplete = userDefaults.bool(forKey: "onboardingComplete")
    }

    func completeOnboarding() {
        isOnboardingComplete = true
        userDefaults.set(true, forKey: "onboardingComplete")
    }

    // MARK: - Emergency Mode
    func activateEmergencyMode() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isEmergencyMode = true
        }
    }

    func deactivateEmergencyMode() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isEmergencyMode = false
        }
    }

    // MARK: - Theme Management
    func setTheme(_ theme: AppTheme) {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentTheme = theme
        }
        userDefaults.set(theme.rawValue, forKey: "appTheme")
    }

    // MARK: - Offline Mode
    func setOfflineMode(_ isOffline: Bool) {
        isOfflineMode = isOffline
    }
}

enum AppTheme: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case emergency = "emergency"

    var colorScheme: ColorScheme {
        switch self {
        case .light: return .light
        case .dark, .emergency: return .dark
        }
    }
}
