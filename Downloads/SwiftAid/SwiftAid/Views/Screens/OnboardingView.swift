//
//  OnboardingView.swift
//  SwiftAid
//
//  Created by AI Assistant on 6/25/25.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var showPermissions = false

    private let pages = [
        OnboardingPage(
            title: "Welcome to SwiftAid",
            subtitle: "Your AI-powered emergency assistant",
            description: "SwiftAid uses advanced AI and motion detection to help you in emergency situations. Get instant first aid guidance and connect with emergency services.",
            image: "heart.text.square.fill",
            color: Color.red
        ),
        OnboardingPage(
            title: "Emergency Detection",
            subtitle: "Automatic fall and crash detection",
            description: "Using your device's sensors, SwiftAid can detect falls, crashes, and other emergencies, automatically alerting emergency contacts and services.",
            image: "figure.fall",
            color: Color.orange
        ),
        OnboardingPage(
            title: "AI First Aid Assistant",
            subtitle: "Expert guidance when you need it",
            description: "Get step-by-step first aid instructions with voice guidance, AR overlays, and real-time assistance for any emergency situation.",
            image: "brain.head.profile",
            color: Color.blue
        ),
        OnboardingPage(
            title: "Health Monitoring",
            subtitle: "Track vitals and health data",
            description: "Connect with HealthKit and Apple Watch to monitor vital signs and detect health emergencies before they become critical.",
            image: "heart.circle.fill",
            color: Color.green
        )
    ]

    var body: some View {
        ZStack {
            GlassmorphicBackground()
                .ignoresSafeArea()

            VStack {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .foregroundColor(.secondary)
                    .padding()
                }

                // Page view
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.5), value: currentPage)

                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.red : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(currentPage == index ? 1.2 : 1.0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: currentPage)
                    }
                }
                .padding()

                // Action buttons
                HStack(spacing: 16) {
                    if currentPage > 0 {
                        Button("Previous") {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .foregroundColor(.secondary)
                    }

                    Spacer()

                    NeumorphicButton(action: {
                        if currentPage < pages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            showPermissions = true
                        }
                    }) {
                        Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.red)
                    )
                }
                .padding()
            }
        }
        .sheet(isPresented: $showPermissions) {
            PermissionsView(isPresented: $showPermissions) {
                completeOnboarding()
            }
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        withAnimation(.easeInOut(duration: 0.5)) {
            isPresented = false
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.2))
                    .frame(width: 150, height: 150)

                Image(systemName: page.image)
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(page.color)
            }

            // Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let description: String
    let image: String
    let color: Color
}

struct PermissionsView: View {
    @Binding var isPresented: Bool
    let completion: () -> Void

    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var notificationManager: NotificationManager

    @State private var permissionsGranted = [false, false, false, false]

    private let permissions = [
        PermissionInfo(
            title: "Location Access",
            description: "Required for emergency location sharing and finding nearby services",
            icon: "location.fill",
            color: Color.blue
        ),
        PermissionInfo(
            title: "Health Data",
            description: "Monitor vital signs and detect health emergencies",
            icon: "heart.fill",
            color: Color.red
        ),
        PermissionInfo(
            title: "Notifications",
            description: "Receive emergency alerts and critical health notifications",
            icon: "bell.fill",
            color: Color.orange
        ),
        PermissionInfo(
            title: "Motion & Fitness",
            description: "Detect falls and crashes using device sensors",
            icon: "figure.walk",
            color: Color.green
        )
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 60))
                        .foregroundColor(.red)

                    Text("Permissions Required")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("SwiftAid needs these permissions to provide life-saving emergency features")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                LazyVStack(spacing: 16) {
                    ForEach(0..<permissions.count, id: \.self) { index in
                        PermissionCard(
                            permission: permissions[index],
                            isGranted: permissionsGranted[index]
                        ) {
                            requestPermission(at: index)
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()

                VStack(spacing: 16) {
                    Button("Continue") {
                        completion()
                        isPresented = false
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .cornerRadius(15)
                    .disabled(!allPermissionsGranted)
                    .opacity(allPermissionsGranted ? 1.0 : 0.6)

                    Button("Maybe Later") {
                        completion()
                        isPresented = false
                    }
                    .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }

    private var allPermissionsGranted: Bool {
        permissionsGranted.allSatisfy { $0 }
    }

    private func requestPermission(at index: Int) {
        switch index {
        case 0: // Location
            locationManager.requestPermission()
            permissionsGranted[0] = true
        case 1: // Health
            healthManager.requestPermission()
            permissionsGranted[1] = true
        case 2: // Notifications
            notificationManager.requestPermission()
            permissionsGranted[2] = true
        case 3: // Motion
            // Motion permission is handled automatically
            permissionsGranted[3] = true
        default:
            break
        }
    }
}

struct PermissionCard: View {
    let permission: PermissionInfo
    let isGranted: Bool
    let action: () -> Void

    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(permission.color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: permission.icon)
                        .font(.title2)
                        .foregroundColor(permission.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(permission.title)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(permission.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Button(action: action) {
                    Image(systemName: isGranted ? "checkmark.circle.fill" : "plus.circle")
                        .font(.title2)
                        .foregroundColor(isGranted ? .green : .blue)
                }
                .disabled(isGranted)
            }
            .padding()
        }
    }
}

struct PermissionInfo {
    let title: String
    let description: String
    let icon: String
    let color: Color
}
