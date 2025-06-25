//
//  ProfileView.swift
//  SwiftAid
//
//  Created by AI Assistant on 6/25/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var notificationManager: NotificationManager

    @State private var showingEditProfile = false
    @State private var showingEmergencyContacts = false
    @State private var showingSettings = false
    @State private var showingExportData = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    profileHeaderSection

                    // Health summary
                    healthSummarySection

                    // Emergency contacts
                    emergencyContactsSection

                    // Settings sections
                    settingsSection

                    // App info
                    appInfoSection
                }
                .padding()
            }
            .background(GlassmorphicBackground().ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                trailing: Button("Edit") {
                    showingEditProfile = true
                }
            )
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
                .environmentObject(appViewModel)
        }
        .sheet(isPresented: $showingEmergencyContacts) {
            EmergencyContactsView()
                .environmentObject(notificationManager)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(appViewModel)
                .environmentObject(locationManager)
                .environmentObject(healthManager)
        }
        .sheet(isPresented: $showingExportData) {
            ExportDataView()
                .environmentObject(appViewModel)
                .environmentObject(healthManager)
        }
    }

    private var profileHeaderSection: some View {
        GlassCard {
            VStack(spacing: 16) {
                // Profile image placeholder
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Text(appViewModel.currentUser.name.isEmpty ? "U" : String(appViewModel.currentUser.name.prefix(1)))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }

                VStack(spacing: 4) {
                    Text(appViewModel.currentUser.name.isEmpty ? "Your Name" : appViewModel.currentUser.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    if let age = appViewModel.currentUser.age {
                        Text("Age: \(age)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if !appViewModel.currentUser.bloodType.isEmpty {
                        Text("Blood Type: \(appViewModel.currentUser.bloodType)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
    }

    private var healthSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Summary")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)

            GlassCard {
                VStack(spacing: 16) {
                    // Health status
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Health Data")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Text(healthManager.healthKitAuthorized ? "Connected" : "Not Connected")
                                .font(.caption)
                                .foregroundColor(healthManager.healthKitAuthorized ? .green : .orange)
                        }

                        Spacer()

                        Image(systemName: healthManager.healthKitAuthorized ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(healthManager.healthKitAuthorized ? .green : .orange)
                    }

                    Divider()

                    // Medical info
                    VStack(alignment: .leading, spacing: 12) {
                        if !appViewModel.currentUser.allergies.isEmpty {
                            InfoRow(title: "Allergies", value: appViewModel.currentUser.allergies.joined(separator: ", "))
                        }

                        if !appViewModel.currentUser.medications.isEmpty {
                            InfoRow(title: "Medications", value: appViewModel.currentUser.medications.joined(separator: ", "))
                        }

                        if !appViewModel.currentUser.medicalConditions.isEmpty {
                            InfoRow(title: "Medical Conditions", value: appViewModel.currentUser.medicalConditions.joined(separator: ", "))
                        }
                    }
                }
                .padding()
            }
        }
    }

    private var emergencyContactsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Emergency Contacts")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button("Manage") {
                    showingEmergencyContacts = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.horizontal)

            if appViewModel.currentUser.emergencyContacts.isEmpty {
                GlassCard {
                    VStack(spacing: 12) {
                        Image(systemName: "person.badge.plus")
                            .font(.largeTitle)
                            .foregroundColor(.orange)

                        Text("No Emergency Contacts")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Text("Add emergency contacts to notify them during emergencies")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button("Add Contact") {
                            showingEmergencyContacts = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding()
                }
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(appViewModel.currentUser.emergencyContacts.prefix(3))) { contact in
                        EmergencyContactRow(contact: contact)
                    }
                }
            }
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)

            VStack(spacing: 12) {
                SettingsRow(
                    title: "App Settings",
                    subtitle: "Preferences, notifications, privacy",
                    icon: "gear",
                    color: .gray
                ) {
                    showingSettings = true
                }

                SettingsRow(
                    title: "Export Health Data",
                    subtitle: "Download your emergency data",
                    icon: "square.and.arrow.up",
                    color: .blue
                ) {
                    showingExportData = true
                }

                SettingsRow(
                    title: "Emergency Services",
                    subtitle: "Local emergency numbers and info",
                    icon: "phone.circle",
                    color: .red
                ) {
                    // Navigate to emergency services
                }

                SettingsRow(
                    title: "About SwiftAid",
                    subtitle: "Version, privacy policy, support",
                    icon: "info.circle",
                    color: .green
                ) {
                    // Navigate to about page
                }
            }
        }
    }

    private var appInfoSection: some View {
        GlassCard {
            VStack(spacing: 12) {
                Image(systemName: "heart.text.square.fill")
                    .font(.largeTitle)
                    .foregroundColor(.red)

                Text("SwiftAid v1.0")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("AI-Powered Emergency Assistant")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Built with ❤️ for emergency preparedness")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
    }
}

struct EmergencyContactRow: View {
    let contact: EmergencyContact

    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Text(String(contact.name.prefix(1)))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(contact.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        if contact.isPrimary {
                            Text("PRIMARY")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .cornerRadius(4)
                        }
                    }

                    Text(contact.relationship)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(contact.phoneNumber)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    if let url = URL(string: "tel://\(contact.phoneNumber)") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Image(systemName: "phone.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                }
            }
            .padding()
        }
    }
}

struct SettingsRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            GlassCard {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.2))
                            .frame(width: 40, height: 40)

                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundColor(color)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Additional Views
struct EditProfileView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var age: String = ""
    @State private var bloodType: String = ""
    @State private var allergies: String = ""
    @State private var medications: String = ""
    @State private var conditions: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Personal Information") {
                    TextField("Full Name", text: $name)
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)

                    Picker("Blood Type", selection: $bloodType) {
                        Text("Select").tag("")
                        Text("A+").tag("A+")
                        Text("A-").tag("A-")
                        Text("B+").tag("B+")
                        Text("B-").tag("B-")
                        Text("AB+").tag("AB+")
                        Text("AB-").tag("AB-")
                        Text("O+").tag("O+")
                        Text("O-").tag("O-")
                    }
                }

                Section("Medical Information") {
                    TextField("Allergies (comma separated)", text: $allergies, axis: .vertical)
                        .lineLimit(2...4)

                    TextField("Current Medications", text: $medications, axis: .vertical)
                        .lineLimit(2...4)

                    TextField("Medical Conditions", text: $conditions, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") { saveProfile() }
            )
            .onAppear {
                loadCurrentProfile()
            }
        }
    }

    private func loadCurrentProfile() {
        let user = appViewModel.currentUser
        name = user.name
        age = user.age != nil ? "\(user.age!)" : ""
        bloodType = user.bloodType
        allergies = user.allergies.joined(separator: ", ")
        medications = user.medications.joined(separator: ", ")
        conditions = user.medicalConditions.joined(separator: ", ")
    }

    private func saveProfile() {
        appViewModel.currentUser.name = name
        appViewModel.currentUser.age = Int(age)
        appViewModel.currentUser.bloodType = bloodType
        appViewModel.currentUser.allergies = allergies.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        appViewModel.currentUser.medications = medications.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        appViewModel.currentUser.medicalConditions = conditions.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        appViewModel.saveUserProfile()
        dismiss()
    }
}

struct EmergencyContactsView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(notificationManager.emergencyContacts) { contact in
                    Text(contact.name)
                }
            }
            .navigationTitle("Emergency Contacts")
            .navigationBarItems(
                leading: Button("Done") { dismiss() },
                trailing: Button("Add") { /* Add contact */ }
            )
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Emergency Settings") {
                    Toggle("Auto-call after fall", isOn: .constant(true))
                    Toggle("Voice alerts", isOn: .constant(true))
                    Toggle("Haptic feedback", isOn: .constant(true))
                }

                Section("Privacy") {
                    Toggle("Share location with emergency services", isOn: .constant(false))
                    Toggle("Share health data during emergencies", isOn: .constant(true))
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct ExportDataView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var healthManager: HealthManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Export Your Data")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Download your emergency profile and health data for backup or sharing with healthcare providers.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)

                Button("Export Data") {
                    exportData()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(15)

                Spacer()
            }
            .padding()
            .navigationTitle("Export Data")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }

    private func exportData() {
        let healthReport = healthManager.exportHealthData()
        // Present share sheet with health report
    }
}
