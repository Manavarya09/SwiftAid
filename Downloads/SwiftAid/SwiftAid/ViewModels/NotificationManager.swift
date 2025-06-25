//
//  NotificationManager.swift
//  SwiftAid
//
//  Created by AI Assistant on 6/25/25.
//

import SwiftUI
import Combine
import UserNotifications
import Firebase
import FirebaseMessaging

class NotificationManager: NSObject, ObservableObject {
    @Published var permissionGranted = false
    @Published var fcmToken: String?
    @Published var emergencyContacts: [EmergencyContact] = []

    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        setupFirebaseMessaging()
        checkPermission()
    }

    private func setupFirebaseMessaging() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound, .criticalAlert]
        ) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.permissionGranted = granted
                if granted {
                    self?.registerForRemoteNotifications()
                }
            }
        }
    }

    private func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.permissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }

    private func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    func sendEmergencyAlert(emergency: EmergencyEvent, location: String) {
        // Send to emergency contacts
        for contact in emergencyContacts where contact.isPrimary {
            sendNotificationToContact(contact, emergency: emergency, location: location)
        }

        // Send local notification
        scheduleLocalEmergencyNotification(emergency: emergency)
    }

    private func sendNotificationToContact(_ contact: EmergencyContact, emergency: EmergencyEvent, location: String) {
        guard let fcmToken = fcmToken else { return }

        let payload: [String: Any] = [
            "to": fcmToken,
            "notification": [
                "title": "SwiftAid Emergency Alert",
                "body": "\(contact.name) needs help. Emergency: \(emergency.type.rawValue) at \(location)",
                "sound": "emergency_alert.wav"
            ],
            "data": [
                "emergency_type": emergency.type.rawValue,
                "location": location,
                "contact_name": contact.name,
                "severity": emergency.severity.rawValue
            ]
        ]

        sendPushNotification(payload: payload)
    }

    private func scheduleLocalEmergencyNotification(emergency: EmergencyEvent) {
        let content = UNMutableNotificationContent()
        content.title = "Emergency Detected"
        content.body = "SwiftAid detected: \(emergency.type.rawValue). Emergency services have been notified."
        content.categoryIdentifier = "EMERGENCY_RESPONSE"
        content.sound = .defaultCritical
        content.interruptionLevel = .critical

        // Add actions
        let callAction = UNNotificationAction(
            identifier: "CALL_911",
            title: "Call 911",
            options: [.foreground]
        )

        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "I'm OK",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: "EMERGENCY_RESPONSE",
            actions: [callAction, dismissAction],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: "",
            options: .customDismissAction
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])

        let request = UNNotificationRequest(
            identifier: "emergency_\(emergency.id.uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func sendPushNotification(payload: [String: Any]) {
        guard let url = URL(string: "https://fcm.googleapis.com/fcm/send") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=YOUR_FCM_SERVER_KEY", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Push notification error: \(error)")
                }
            }.resume()
        } catch {
            print("Failed to serialize notification payload: \(error)")
        }
    }

    func scheduleVitalSignsAlert(vitals: VitalSigns) {
        let content = UNMutableNotificationContent()
        content.title = "Abnormal Vital Signs Detected"
        content.body = "Your vital signs are outside normal ranges. Consider seeking medical attention."
        content.categoryIdentifier = "HEALTH_ALERT"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "vitals_alert_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func updateEmergencyContacts(_ contacts: [EmergencyContact]) {
        emergencyContacts = contacts
        // Save to UserDefaults or Firebase
        saveEmergencyContacts()
    }

    private func saveEmergencyContacts() {
        if let encoded = try? JSONEncoder().encode(emergencyContacts) {
            UserDefaults.standard.set(encoded, forKey: "emergencyContacts")
        }
    }

    private func loadEmergencyContacts() {
        if let data = UserDefaults.standard.data(forKey: "emergencyContacts"),
           let contacts = try? JSONDecoder().decode([EmergencyContact].self, from: data) {
            emergencyContacts = contacts
        }
    }
}

// MARK: - Firebase Messaging Delegate
extension NotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        self.fcmToken = fcmToken
        // Send token to your server for device-to-device messaging
    }
}

// MARK: - User Notification Center Delegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.badge, .sound, .banner])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {

        switch response.actionIdentifier {
        case "CALL_911":
            if let url = URL(string: "tel://911") {
                UIApplication.shared.open(url)
            }
        case "DISMISS":
            // Handle dismissal
            break
        default:
            break
        }

        completionHandler()
    }
}
