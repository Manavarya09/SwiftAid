//
//  HealthManager.swift
//  SwiftAid
//
//  Created by AI Assistant on 6/25/25.
//

import SwiftUI
import Combine
import HealthKit
import WatchConnectivity

class HealthManager: NSObject, ObservableObject {
    @Published var isHealthDataAvailable = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published var currentVitals: VitalSigns = VitalSigns()
    @Published var healthKitAuthorized = false
    @Published var watchConnected = false

    private let healthStore = HKHealthStore()
    private var cancellables = Set<AnyCancellable>()
    private var healthObservers: [HKObserverQuery] = []

    // Health data types we want to read
    private let readTypes: Set<HKObjectType> = [
        HKQuantityType.quantityType(forIdentifier: .heartRate)!,
        HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!,
        HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
        HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!,
        HKQuantityType.quantityType(forIdentifier: .bodyTemperature)!,
        HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!,
        HKQuantityType.quantityType(forIdentifier: .stepCount)!,
        HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
    ]

    override init() {
        super.init()
        setupHealthKit()
        setupWatchConnectivity()
    }

    private func setupHealthKit() {
        isHealthDataAvailable = HKHealthStore.isHealthDataAvailable()
    }

    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    func requestPermission() {
        guard isHealthDataAvailable else { return }

        healthStore.requestAuthorization(toShare: [], read: readTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.healthKitAuthorized = success
                if success {
                    self?.startHealthDataObservation()
                    self?.fetchLatestVitals()
                }
            }
        }
    }

    private func startHealthDataObservation() {
        // Observe heart rate changes
        if let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            observeHealthData(for: heartRateType) { [weak self] samples in
                self?.processHeartRateData(samples)
            }
        }

        // Observe other vital signs
        observeVitalSigns()
    }

    private func observeHealthData(for type: HKQuantityType, completion: @escaping ([HKQuantitySample]) -> Void) {
        let query = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, _, error in
            guard error == nil else { return }
            self?.fetchLatestSamples(for: type, completion: completion)
        }

        healthStore.execute(query)
        healthObservers.append(query)
    }

    private func fetchLatestSamples(for type: HKQuantityType, completion: @escaping ([HKQuantitySample]) -> Void) {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: type,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, _ in
            completion(samples as? [HKQuantitySample] ?? [])
        }

        healthStore.execute(query)
    }

    private func observeVitalSigns() {
        // Observe multiple vital signs
        let vitalTypes = [
            HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
            HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKQuantityType.quantityType(forIdentifier: .bodyTemperature)!,
            HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!
        ]

        for type in vitalTypes {
            observeHealthData(for: type) { [weak self] samples in
                self?.processVitalSignData(samples, for: type)
            }
        }
    }

    private func processHeartRateData(_ samples: [HKQuantitySample]) {
        guard let sample = samples.first else { return }

        let heartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))

        DispatchQueue.main.async {
            self.currentVitals.heartRate = heartRate
            self.checkForAbnormalVitals()
        }
    }

    private func processVitalSignData(_ samples: [HKQuantitySample], for type: HKQuantityType) {
        guard let sample = samples.first else { return }

        DispatchQueue.main.async {
            switch type.identifier {
            case HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue:
                self.currentVitals.bloodPressureSystolic = sample.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
            case HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue:
                self.currentVitals.bloodPressureDiastolic = sample.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
            case HKQuantityTypeIdentifier.oxygenSaturation.rawValue:
                self.currentVitals.oxygenSaturation = sample.quantity.doubleValue(for: HKUnit.percent()) * 100
            case HKQuantityTypeIdentifier.bodyTemperature.rawValue:
                self.currentVitals.temperature = sample.quantity.doubleValue(for: HKUnit.degreeFahrenheit())
            case HKQuantityTypeIdentifier.respiratoryRate.rawValue:
                self.currentVitals.respiratoryRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
            default:
                break
            }

            self.checkForAbnormalVitals()
        }
    }

    private func fetchLatestVitals() {
        // Fetch the most recent vital signs data
        let vitalTypes = [
            (HKQuantityType.quantityType(forIdentifier: .heartRate)!, HKUnit.count().unitDivided(by: HKUnit.minute())),
            (HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!, HKUnit.millimeterOfMercury()),
            (HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!, HKUnit.millimeterOfMercury()),
            (HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!, HKUnit.percent()),
            (HKQuantityType.quantityType(forIdentifier: .bodyTemperature)!, HKUnit.degreeFahrenheit()),
            (HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!, HKUnit.count().unitDivided(by: HKUnit.minute()))
        ]

        for (type, unit) in vitalTypes {
            fetchLatestSamples(for: type) { [weak self] samples in
                guard let sample = samples.first else { return }

                DispatchQueue.main.async {
                    let value = sample.quantity.doubleValue(for: unit)

                    switch type.identifier {
                    case HKQuantityTypeIdentifier.heartRate.rawValue:
                        self?.currentVitals.heartRate = value
                    case HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue:
                        self?.currentVitals.bloodPressureSystolic = value
                    case HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue:
                        self?.currentVitals.bloodPressureDiastolic = value
                    case HKQuantityTypeIdentifier.oxygenSaturation.rawValue:
                        self?.currentVitals.oxygenSaturation = value * 100
                    case HKQuantityTypeIdentifier.bodyTemperature.rawValue:
                        self?.currentVitals.temperature = value
                    case HKQuantityTypeIdentifier.respiratoryRate.rawValue:
                        self?.currentVitals.respiratoryRate = value
                    default:
                        break
                    }
                }
            }
        }
    }

    private func checkForAbnormalVitals() {
        if currentVitals.isAbnormal {
            // Trigger health alert
            NotificationCenter.default.post(name: .abnormalVitalsDetected, object: currentVitals)
        }
    }

    func exportHealthData() -> String {
        var healthReport = "SwiftAid Health Report\n"
        healthReport += "Generated: \(Date())\n\n"

        if let heartRate = currentVitals.heartRate {
            healthReport += "Heart Rate: \(Int(heartRate)) BPM\n"
        }

        if let systolic = currentVitals.bloodPressureSystolic,
           let diastolic = currentVitals.bloodPressureDiastolic {
            healthReport += "Blood Pressure: \(Int(systolic))/\(Int(diastolic)) mmHg\n"
        }

        if let oxygen = currentVitals.oxygenSaturation {
            healthReport += "Oxygen Saturation: \(String(format: "%.1f", oxygen))%\n"
        }

        if let temp = currentVitals.temperature {
            healthReport += "Temperature: \(String(format: "%.1f", temp))°F\n"
        }

        return healthReport
    }
}

extension HealthManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.watchConnected = (activationState == .activated)
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // Handle messages from Apple Watch
        if let vitalsData = message["vitals"] as? [String: Double] {
            DispatchQueue.main.async {
                if let heartRate = vitalsData["heartRate"] {
                    self.currentVitals.heartRate = heartRate
                }
                // Process other vital signs from watch
                self.checkForAbnormalVitals()
            }
        }
    }
}

extension Notification.Name {
    static let abnormalVitalsDetected = Notification.Name("abnormalVitalsDetected")
}
