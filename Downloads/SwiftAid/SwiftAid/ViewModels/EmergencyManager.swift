//
//  EmergencyManager.swift
//  SwiftAid
//
//  Created by AI Assistant on 6/25/25.
//

import SwiftUI
import Combine
import CoreMotion
import Foundation
import UserNotifications
import AVFoundation
import CallKit

class EmergencyManager: NSObject, ObservableObject {
    @Published var emergencyDetected = false
    @Published var currentEmergency: EmergencyEvent?
    @Published var isMonitoring = false
    @Published var fallDetected = false
    @Published var vitals: VitalSigns?
    @Published var emergencyCountdown = 0

    private let motionManager = CMMotionManager()
    private let altimeter = CMAltimeter()
    private var cancellables = Set<AnyCancellable>()
    private let synthesizer = AVSpeechSynthesizer()
    private let callObserver = CXCallObserver()

    // Emergency detection thresholds
    private let fallThreshold: Double = 2.5 // G-force
    private let shakeThreshold: Double = 3.0
    private let heartRateThreshold: (min: Double, max: Double) = (40, 150)

    private var emergencyTimer: Timer?
    private var countdownTimer: Timer?

    override init() {
        super.init()
        setupMotionDetection()
        setupCallObserver()
    }

    // MARK: - Emergency Detection
    func startMonitoring() {
        guard !isMonitoring else { return }

        isMonitoring = true
        startAccelerometerUpdates()
        startGyroscopeUpdates()

        // Start continuous monitoring
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.analyzeMotionData()
        }
    }

    func stopMonitoring() {
        isMonitoring = false
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        emergencyTimer?.invalidate()
        countdownTimer?.invalidate()
    }

    private func setupMotionDetection() {
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.gyroUpdateInterval = 0.1
    }

    private func startAccelerometerUpdates() {
        guard motionManager.isAccelerometerAvailable else { return }

        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let data = data else { return }
            self.processAccelerometerData(data)
        }
    }

    private func startGyroscopeUpdates() {
        guard motionManager.isGyroAvailable else { return }

        motionManager.startGyroUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let data = data else { return }
            self.processGyroscopeData(data)
        }
    }

    private func processAccelerometerData(_ data: CMAccelerometerData) {
        let acceleration = sqrt(pow(data.acceleration.x, 2) + 
                               pow(data.acceleration.y, 2) + 
                               pow(data.acceleration.z, 2))

        // Detect fall or sudden impact
        if acceleration > fallThreshold {
            detectFall()
        }

        // Detect shake gesture for SOS
        if acceleration > shakeThreshold {
            detectShakeGesture()
        }
    }

    private func processGyroscopeData(_ data: CMGyroData) {
        let rotationRate = sqrt(pow(data.rotationRate.x, 2) + 
                               pow(data.rotationRate.y, 2) + 
                               pow(data.rotationRate.z, 2))

        // Additional motion analysis can be added here
    }

    private func analyzeMotionData() {
        // Combine accelerometer and gyroscope data for advanced detection
        // This would integrate with CoreML models for more accurate detection
    }

    // MARK: - Emergency Events
    private func detectFall() {
        guard !fallDetected else { return }

        fallDetected = true
        let emergency = EmergencyEvent(
            type: .fall,
            timestamp: Date(),
            description: "Fall detected by motion sensors",
            severity: .high,
            status: .detecting
        )

        triggerEmergency(emergency)

        // Reset fall detection after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.fallDetected = false
        }
    }

    private func detectShakeGesture() {
        let emergency = EmergencyEvent(
            type: .medical,
            timestamp: Date(),
            description: "SOS shake gesture detected",
            severity: .medium,
            status: .detecting
        )

        triggerEmergency(emergency)
    }

    func triggerEmergency(_ emergency: EmergencyEvent) {
        currentEmergency = emergency
        startEmergencyCountdown()

        // Speak emergency message
        speakEmergencyMessage()

        // Send notifications
        sendEmergencyNotification()

        // Haptic feedback
        triggerHapticFeedback()
    }

    private func startEmergencyCountdown() {
        emergencyCountdown = 30 // 30 second countdown
        emergencyDetected = true

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            self.emergencyCountdown -= 1

            if self.emergencyCountdown <= 0 {
                timer.invalidate()
                self.initiateEmergencyCall()
            }
        }
    }

    func dismissEmergency() {
        emergencyDetected = false
        countdownTimer?.invalidate()
        currentEmergency = nil
        emergencyCountdown = 0
    }

    func initiateEmergencyCall() {
        guard let emergency = currentEmergency else { return }

        let phoneNumber = emergency.type.emergencyNumber
        if let url = URL(string: "tel://\(phoneNumber)") {
            DispatchQueue.main.async {
                UIApplication.shared.open(url)
            }
        }

        // Update emergency status
        var updatedEmergency = emergency
        updatedEmergency.status = .responding
        currentEmergency = updatedEmergency
    }

    func showAssistance() {
        // Navigate to AI Assistant or First Aid view
        emergencyDetected = false
        countdownTimer?.invalidate()
    }

    // MARK: - Voice & Audio
    private func speakEmergencyMessage() {
        let message = "Emergency detected. I will call 911 in 30 seconds unless you cancel."
        let utterance = AVSpeechUtterance(string: message)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.volume = 1.0

        synthesizer.speak(utterance)
    }

    // MARK: - Notifications
    private func sendEmergencyNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Emergency Detected"
        content.body = "SwiftAid has detected a potential emergency. Tap to respond."
        content.categoryIdentifier = "EMERGENCY"
        content.sound = .defaultCritical

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Haptic Feedback
    private func triggerHapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()

        // Continuous vibration pattern for emergency
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            impactFeedback.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            impactFeedback.impactOccurred()
        }
    }

    // MARK: - Call Observer
    private func setupCallObserver() {
        callObserver.setDelegate(self, queue: nil)
    }
}

extension EmergencyManager: CXCallObserverDelegate {
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        if call.hasEnded {
            // Call ended - update emergency status if needed
            if var emergency = currentEmergency, emergency.status == .responding {
                emergency.status = .resolved
                currentEmergency = emergency
            }
        }
    }
}
