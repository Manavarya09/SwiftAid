//
//  ARFirstAidView.swift
//  SwiftAid
//
//  Created by AI Assistant on 6/25/25.
//

import SwiftUI
import ARKit
import AVFoundation

struct ARFirstAidView: View {
    @StateObject private var arManager = ARFirstAidManager()
    @State private var selectedEmergencyType: EmergencyType = .heartAttack
    @State private var showingInstructions = false
    @State private var isRecording = false

    var body: some View {
        NavigationView {
            ZStack {
                // AR Camera View
                ARViewContainer(arManager: arManager)
                    .ignoresSafeArea()

                // Overlay UI
                VStack {
                    // Top controls
                    topControlsSection

                    Spacer()

                    // Bottom controls
                    bottomControlsSection
                }
            }
            .navigationTitle("AR First Aid")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Instructions") {
                    showingInstructions = true
                },
                trailing: Button(isRecording ? "Stop" : "Record") {
                    toggleRecording()
                }
                .foregroundColor(isRecording ? .red : .blue)
            )
        }
        .sheet(isPresented: $showingInstructions) {
            FirstAidInstructionsView(emergencyType: selectedEmergencyType)
        }
        .onAppear {
            arManager.startARSession()
        }
        .onDisappear {
            arManager.stopARSession()
        }
    }

    private var topControlsSection: some View {
        HStack {
            // Emergency type selector
            GlassCard {
                Picker("Emergency Type", selection: $selectedEmergencyType) {
                    ForEach(EmergencyType.allCases, id: \.self) { type in
                        HStack {
                            Image(systemName: type.icon)
                            Text(type.rawValue.capitalized)
                        }
                        .tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }

            Spacer()

            // AR status indicator
            GlassCard {
                HStack(spacing: 8) {
                    Circle()
                        .fill(arManager.isARActive ? Color.green : Color.red)
                        .frame(width: 8, height: 8)

                    Text(arManager.isARActive ? "AR Active" : "AR Inactive")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }

    private var bottomControlsSection: some View {
        VStack(spacing: 16) {
            // AR Instructions overlay
            if arManager.isShowingInstructions {
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Step \(arManager.currentStep + 1) of \(arManager.totalSteps)")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            Button("Hide") {
                                arManager.hideInstructions()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }

                        Text(arManager.currentInstruction)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(3)

                        HStack {
                            Button("Previous") {
                                arManager.previousStep()
                            }
                            .disabled(arManager.currentStep == 0)

                            Spacer()

                            Button("Next") {
                                arManager.nextStep()
                            }
                            .disabled(arManager.currentStep >= arManager.totalSteps - 1)
                        }
                        .font(.caption)
                    }
                    .padding()
                }
                .padding(.horizontal)
            }

            // Control buttons
            HStack(spacing: 20) {
                // Start/Stop instructions
                NeumorphicButton(action: {
                    if arManager.isShowingInstructions {
                        arManager.hideInstructions()
                    } else {
                        arManager.showInstructions(for: selectedEmergencyType)
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: arManager.isShowingInstructions ? "stop.fill" : "play.fill")
                            .font(.title2)
                            .foregroundColor(.white)

                        Text(arManager.isShowingInstructions ? "Stop" : "Start")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                }
                .background(
                    Circle()
                        .fill(arManager.isShowingInstructions ? Color.red : Color.green)
                        .frame(width: 70, height: 70)
                )

                // Emergency call
                NeumorphicButton(action: {
                    callEmergencyServices()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "phone.fill")
                            .font(.title2)
                            .foregroundColor(.white)

                        Text("911")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                .background(
                    Circle()
                        .fill(Color.red)
                        .frame(width: 70, height: 70)
                )
                .emergencyGlow()

                // Reset AR
                NeumorphicButton(action: {
                    arManager.resetARSession()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                            .foregroundColor(.primary)

                        Text("Reset")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private func toggleRecording() {
        if isRecording {
            arManager.stopRecording()
        } else {
            arManager.startRecording()
        }
        isRecording.toggle()
    }

    private func callEmergencyServices() {
        if let url = URL(string: "tel://911") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - AR View Container
struct ARViewContainer: UIViewRepresentable {
    let arManager: ARFirstAidManager

    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        arView.delegate = arManager
        arView.session.delegate = arManager

        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        arView.session.run(configuration)

        arManager.arView = arView
        return arView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Update AR view if needed
    }
}

// MARK: - AR First Aid Manager
class ARFirstAidManager: NSObject, ObservableObject {
    @Published var isARActive = false
    @Published var isShowingInstructions = false
    @Published var currentStep = 0
    @Published var totalSteps = 0
    @Published var currentInstruction = ""

    var arView: ARSCNView?
    private var instructionNodes: [SCNNode] = []
    private var currentEmergencyType: EmergencyType?

    // First aid instructions database
    private let firstAidInstructions: [EmergencyType: [String]] = [
        .heartAttack: [
            "Call 911 immediately",
            "Help the person sit down comfortably",
            "Loosen any tight clothing around neck and chest",
            "Give aspirin if available and person is not allergic",
            "Monitor breathing and pulse",
            "Be prepared to perform CPR if needed"
        ],
        .choking: [
            "Stand behind the person",
            "Place your arms around their waist",
            "Make a fist with one hand",
            "Place fist above navel, below ribcage",
            "Grasp fist with other hand",
            "Perform quick upward thrusts",
            "Continue until object is expelled"
        ],
        .bleeding: [
            "Apply direct pressure to wound",
            "Use clean cloth or bandage",
            "Maintain firm, steady pressure",
            "Elevate injured area above heart if possible",
            "Add more layers if blood soaks through",
            "Seek immediate medical attention"
        ]
    ]

    func startARSession() {
        isARActive = true
    }

    func stopARSession() {
        isARActive = false
        arView?.session.pause()
    }

    func resetARSession() {
        hideInstructions()
        arView?.scene.rootNode.childNodes.forEach { $0.removeFromParentNode() }

        if let configuration = arView?.session.configuration {
            arView?.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }
    }

    func showInstructions(for emergencyType: EmergencyType) {
        currentEmergencyType = emergencyType
        let instructions = firstAidInstructions[emergencyType] ?? []

        totalSteps = instructions.count
        currentStep = 0
        currentInstruction = instructions.first ?? ""
        isShowingInstructions = true

        // Add AR instruction overlays
        addInstructionOverlays(instructions)
    }

    func hideInstructions() {
        isShowingInstructions = false
        removeInstructionOverlays()
    }

    func nextStep() {
        guard currentStep < totalSteps - 1 else { return }
        currentStep += 1
        updateCurrentInstruction()
        updateAROverlay()
    }

    func previousStep() {
        guard currentStep > 0 else { return }
        currentStep -= 1
        updateCurrentInstruction()
        updateAROverlay()
    }

    private func updateCurrentInstruction() {
        guard let emergencyType = currentEmergencyType,
              let instructions = firstAidInstructions[emergencyType],
              currentStep < instructions.count else { return }

        currentInstruction = instructions[currentStep]
    }

    private func addInstructionOverlays(_ instructions: [String]) {
        guard let arView = arView else { return }

        // Create 3D text nodes for instructions
        for (index, instruction) in instructions.enumerated() {
            let textGeometry = SCNText(string: "\(index + 1). \(instruction)", extrusionDepth: 0.02)
            textGeometry.font = UIFont.systemFont(ofSize: 0.1)
            textGeometry.firstMaterial?.diffuse.contents = UIColor.white

            let textNode = SCNNode(geometry: textGeometry)
            textNode.position = SCNVector3(0, Float(index) * 0.2 - 1.0, -2.0)
            textNode.scale = SCNVector3(0.5, 0.5, 0.5)
            textNode.isHidden = index != 0 // Only show first instruction initially

            arView.scene.rootNode.addChildNode(textNode)
            instructionNodes.append(textNode)
        }
    }

    private func removeInstructionOverlays() {
        instructionNodes.forEach { $0.removeFromParentNode() }
        instructionNodes.removeAll()
    }

    private func updateAROverlay() {
        // Hide all instruction nodes
        instructionNodes.forEach { $0.isHidden = true }

        // Show current step
        if currentStep < instructionNodes.count {
            instructionNodes[currentStep].isHidden = false
        }
    }

    func startRecording() {
        // Implement video recording functionality
        arView?.session.delegate = self
    }

    func stopRecording() {
        // Stop video recording
    }
}

// MARK: - ARSCNViewDelegate
extension ARFirstAidManager: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Handle AR anchors if needed
    }
}

// MARK: - ARSessionDelegate
extension ARFirstAidManager: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Handle AR frame updates
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        print("AR Session failed: \(error.localizedDescription)")
        isARActive = false
    }
}

// MARK: - First Aid Instructions View
struct FirstAidInstructionsView: View {
    let emergencyType: EmergencyType
    @Environment(\.dismiss) private var dismiss

    private let instructions: [EmergencyType: FirstAidInstruction] = [
        .heartAttack: FirstAidInstruction(
            title: "Heart Attack First Aid",
            steps: [
                "Call 911 immediately",
                "Help person sit down and rest",
                "Loosen tight clothing",
                "Give aspirin if available (not allergic)",
                "Monitor breathing and pulse",
                "Be ready to perform CPR"
            ],
            emergencyType: .heartAttack,
            estimatedTime: 300
        ),
        .choking: FirstAidInstruction(
            title: "Choking First Aid",
            steps: [
                "Stand behind the person",
                "Place arms around waist",
                "Make fist above navel",
                "Perform upward thrusts",
                "Continue until object expelled",
                "Call 911 if unsuccessful"
            ],
            emergencyType: .choking,
            estimatedTime: 180
        )
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color(emergencyType.color).opacity(0.2))
                                .frame(width: 100, height: 100)

                            Image(systemName: emergencyType.icon)
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundColor(Color(emergencyType.color))
                        }

                        Text(instructions[emergencyType]?.title ?? "First Aid Instructions")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                    }

                    // Steps
                    if let instruction = instructions[emergencyType] {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(instruction.steps.enumerated()), id: \.offset) { index, step in
                                GlassCard {
                                    HStack(alignment: .top, spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(Color(emergencyType.color))
                                                .frame(width: 32, height: 32)

                                            Text("\(index + 1)")
                                                .font(.headline)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                        }

                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(step)
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .lineLimit(nil)
                                        }

                                        Spacer()
                                    }
                                    .padding()
                                }
                            }
                        }
                    }

                    // Warning section
                    GlassCard {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.title2)
                                    .foregroundColor(.orange)

                                Text("Important Reminders")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("• Always call 911 first in serious emergencies")
                                Text("• Stay calm and speak clearly to the person")
                                Text("• Don't move the person unless they're in immediate danger")
                                Text("• Continue monitoring until help arrives")
                            }
                            .font(.body)
                            .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Instructions")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
    }
}
