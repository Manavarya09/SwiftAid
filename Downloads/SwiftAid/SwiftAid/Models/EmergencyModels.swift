//
//  EmergencyModels.swift
//  SwiftAid
//
//  Created by AI Assistant on 6/25/25.
//

import Foundation
import CoreLocation
import HealthKit

// MARK: - Emergency Types
enum EmergencyType: String, CaseIterable, Codable {
    case medical = "medical"
    case fire = "fire"
    case police = "police"
    case naturalDisaster = "natural_disaster"
    case accident = "accident"
    case fall = "fall"
    case heartAttack = "heart_attack"
    case stroke = "stroke"
    case choking = "choking"
    case bleeding = "bleeding"
    case poisoning = "poisoning"
    case unconscious = "unconscious"

    var icon: String {
        switch self {
        case .medical: return "cross.fill"
        case .fire: return "flame.fill"
        case .police: return "shield.fill"
        case .naturalDisaster: return "cloud.bolt.rain.fill"
        case .accident: return "car.fill"
        case .fall: return "figure.fall"
        case .heartAttack: return "heart.fill"
        case .stroke: return "brain.head.profile"
        case .choking: return "lungs.fill"
        case .bleeding: return "drop.fill"
        case .poisoning: return "exclamationmark.triangle.fill"
        case .unconscious: return "person.crop.circle.badge.exclamationmark"
        }
    }

    var color: String {
        switch self {
        case .medical, .heartAttack, .bleeding: return "red"
        case .fire: return "orange"
        case .police: return "blue"
        case .naturalDisaster: return "purple"
        case .accident: return "yellow"
        case .fall, .unconscious: return "gray"
        case .stroke, .choking, .poisoning: return "red"
        }
    }

    var emergencyNumber: String {
        switch self {
        case .medical, .heartAttack, .stroke, .choking, .bleeding, .poisoning, .unconscious, .fall:
            return "911"
        case .fire:
            return "911"
        case .police:
            return "911"
        case .naturalDisaster, .accident:
            return "911"
        }
    }
}

// MARK: - Emergency Contact
struct EmergencyContact: Identifiable, Codable {
    let id = UUID()
    var name: String
    var phoneNumber: String
    var relationship: String
    var isPrimary: Bool = false
    var location: CLLocationCoordinate2D?

    private enum CodingKeys: String, CodingKey {
        case name, phoneNumber, relationship, isPrimary
    }
}

// MARK: - Emergency Event
struct EmergencyEvent: Identifiable, Codable {
    let id = UUID()
    var type: EmergencyType
    var timestamp: Date
    var location: CLLocationCoordinate2D?
    var description: String
    var severity: EmergencySeverity
    var status: EmergencyStatus
    var responders: [String] = []
    var vitals: VitalSigns?
    var isResolved: Bool = false
    var notes: String = ""

    private enum CodingKeys: String, CodingKey {
        case type, timestamp, description, severity, status, responders, isResolved, notes
    }
}

enum EmergencySeverity: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"

    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}

enum EmergencyStatus: String, CaseIterable, Codable {
    case detecting = "detecting"
    case confirmed = "confirmed"
    case responding = "responding"
    case resolved = "resolved"
    case falseAlarm = "false_alarm"
}

// MARK: - Vital Signs
struct VitalSigns: Codable {
    var heartRate: Double?
    var bloodPressureSystolic: Double?
    var bloodPressureDiastolic: Double?
    var oxygenSaturation: Double?
    var temperature: Double?
    var respiratoryRate: Double?
    var timestamp: Date = Date()

    var isAbnormal: Bool {
        if let hr = heartRate, hr < 60 || hr > 100 { return true }
        if let sys = bloodPressureSystolic, sys > 140 || sys < 90 { return true }
        if let o2 = oxygenSaturation, o2 < 95 { return true }
        if let temp = temperature, temp > 100.4 || temp < 95 { return true }
        return false
    }
}

// MARK: - First Aid Instructions
struct FirstAidInstruction: Identifiable, Codable {
    let id = UUID()
    var title: String
    var steps: [String]
    var emergencyType: EmergencyType
    var videoURL: String?
    var images: [String] = []
    var warnings: [String] = []
    var estimatedTime: TimeInterval
}

// MARK: - AI Chat Message
struct ChatMessage: Identifiable, Codable {
    let id = UUID()
    var content: String
    var isFromUser: Bool
    var timestamp: Date = Date()
    var emergencyType: EmergencyType?
    var actionRequired: Bool = false
    var suggestions: [String] = []
}

// MARK: - Location Data
struct EmergencyLocation: Codable {
    var coordinate: CLLocationCoordinate2D
    var address: String?
    var timestamp: Date = Date()
    var accuracy: Double

    private enum CodingKeys: String, CodingKey {
        case address, timestamp, accuracy
    }
}

// MARK: - User Profile
struct UserProfile: Codable {
    var name: String = ""
    var age: Int?
    var bloodType: String = ""
    var allergies: [String] = []
    var medications: [String] = []
    var medicalConditions: [String] = []
    var emergencyContacts: [EmergencyContact] = []
    var preferences: UserPreferences = UserPreferences()
}

struct UserPreferences: Codable {
    var language: String = "en"
    var enableVoiceAlerts: Bool = true
    var enableHapticFeedback: Bool = true
    var emergencyTimeout: TimeInterval = 30.0
    var autoCallAfterFall: Bool = true
    var shareLocationAlways: Bool = false
}
