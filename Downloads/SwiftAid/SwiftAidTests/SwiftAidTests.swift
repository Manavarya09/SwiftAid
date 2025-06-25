//
//  SwiftAidTests.swift
//  SwiftAidTests
//
//  Created by AI Assistant on 6/25/25.
//

import XCTest
@testable import SwiftAid

final class SwiftAidTests: XCTestCase {

    var emergencyManager: EmergencyManager!
    var locationManager: LocationManager!
    var healthManager: HealthManager!

    override func setUpWithError() throws {
        emergencyManager = EmergencyManager()
        locationManager = LocationManager()
        healthManager = HealthManager()
    }

    override func tearDownWithError() throws {
        emergencyManager = nil
        locationManager = nil
        healthManager = nil
    }

    func testEmergencyDetection() throws {
        // Test emergency detection logic
        XCTAssertFalse(emergencyManager.emergencyDetected)

        let testEmergency = EmergencyEvent(
            type: .fall,
            timestamp: Date(),
            description: "Test fall detection",
            severity: .high,
            status: .detecting
        )

        emergencyManager.triggerEmergency(testEmergency)
        XCTAssertTrue(emergencyManager.emergencyDetected)
    }

    func testVitalSigns() throws {
        var vitals = VitalSigns()
        vitals.heartRate = 120
        vitals.oxygenSaturation = 95

        XCTAssertTrue(vitals.isAbnormal) // Heart rate over 100

        vitals.heartRate = 75
        XCTAssertFalse(vitals.isAbnormal) // Normal range
    }

    func testEmergencyTypes() throws {
        let heartAttack = EmergencyType.heartAttack
        XCTAssertEqual(heartAttack.emergencyNumber, "911")
        XCTAssertEqual(heartAttack.icon, "heart.fill")
    }

    func testUserProfile() throws {
        var profile = UserProfile()
        profile.name = "Test User"
        profile.bloodType = "O+"
        profile.allergies = ["Peanuts", "Shellfish"]

        XCTAssertEqual(profile.name, "Test User")
        XCTAssertEqual(profile.bloodType, "O+")
        XCTAssertEqual(profile.allergies.count, 2)
    }

    func testEmergencyContact() throws {
        let contact = EmergencyContact(
            name: "John Doe",
            phoneNumber: "+1-555-123-4567",
            relationship: "Spouse",
            isPrimary: true
        )

        XCTAssertEqual(contact.name, "John Doe")
        XCTAssertTrue(contact.isPrimary)
    }

    func testLocationFormatting() throws {
        let testNumber = "5551234567"
        let formatted = testNumber.phoneNumberFormatted()
        XCTAssertEqual(formatted, "(555) 123-4567")
    }
}
