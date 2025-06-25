//
//  ContentView.swift
//  SwiftAid
//
//  Created by AI Assistant on 6/25/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var emergencyManager: EmergencyManager
    @State private var showOnboarding = true
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            // Background gradient
            GlassmorphicBackground()
                .ignoresSafeArea()

            if showOnboarding {
                OnboardingView(isPresented: $showOnboarding)
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                mainTabView
            }
        }
        .onAppear {
            checkFirstLaunch()
        }
        .alert("Emergency Detected!", isPresented: $emergencyManager.emergencyDetected) {
            Button("Call 911", role: .destructive) {
                emergencyManager.initiateEmergencyCall()
            }
            Button("False Alarm") {
                emergencyManager.dismissEmergency()
            }
            Button("Get Help") {
                emergencyManager.showAssistance()
            }
        } message: {
            Text("We've detected a potential emergency. How would you like to proceed?")
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
                .tag(0)

            EmergencyMapView()
                .tabItem {
                    Image(systemName: "location.fill")
                    Text("Emergency Map")
                }
                .tag(1)

            ARFirstAidView()
                .tabItem {
                    Image(systemName: "camera.viewfinder")
                    Text("AR First Aid")
                }
                .tag(2)

            AIAssistantView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("AI Assistant")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
                }
                .tag(4)
        }
        .accentColor(.red)
        .preferredColorScheme(.dark)
    }

    private func checkFirstLaunch() {
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        if hasLaunchedBefore {
            showOnboarding = false
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppViewModel())
            .environmentObject(EmergencyManager())
            .environmentObject(LocationManager())
            .environmentObject(HealthManager())
            .environmentObject(NotificationManager())
    }
}
