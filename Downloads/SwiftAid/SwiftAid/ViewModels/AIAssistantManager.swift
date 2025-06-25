//
//  AIAssistantManager.swift
//  SwiftAid
//
//  Created by AI Assistant on 6/25/25.
//

import SwiftUI
import Combine
import Foundation
import Speech
import AVFoundation
import CoreML
import NaturalLanguage

class AIAssistantManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isListening = false
    @Published var isProcessing = false
    @Published var currentLanguage = "en-US"
    @Published var voiceEnabled = true

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var cancellables = Set<AnyCancellable>()

    // Emergency response knowledge base
    private let emergencyResponses: [String: [String]] = [
        "heart attack": [
            "Call 911 immediately",
            "Have the person sit or lie down comfortably",
            "Give aspirin if available and not allergic",
            "Loosen tight clothing",
            "Monitor breathing and pulse",
            "Be prepared to perform CPR if needed"
        ],
        "choking": [
            "For conscious adult: Perform Heimlich maneuver",
            "Stand behind the person",
            "Place arms around their waist",
            "Make upward thrusts below ribcage",
            "Continue until object is expelled",
            "Call 911 if unsuccessful"
        ],
        "bleeding": [
            "Apply direct pressure to wound",
            "Elevate injured area above heart if possible",
            "Use clean cloth or bandage",
            "Don't remove embedded objects",
            "Monitor for shock symptoms",
            "Seek medical attention for severe bleeding"
        ],
        "stroke": [
            "Use F.A.S.T. test: Face, Arms, Speech, Time",
            "Call 911 immediately",
            "Note time symptoms started",
            "Keep person comfortable and calm",
            "Don't give food or water",
            "Monitor vital signs"
        ],
        "fall": [
            "Don't move the person unnecessarily",
            "Check for consciousness and breathing",
            "Look for obvious injuries",
            "Call 911 if head injury or can't move",
            "Apply ice to swelling",
            "Monitor for signs of concussion"
        ]
    ]

    init() {
        setupSpeechRecognition()
        addInitialMessage()
    }

    private func setupSpeechRecognition() {
        speechRecognizer?.delegate = self
        requestSpeechPermission()
    }

    private func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("Speech recognition authorized")
                case .denied, .restricted, .notDetermined:
                    print("Speech recognition not authorized")
                @unknown default:
                    break
                }
            }
        }
    }

    private func addInitialMessage() {
        let welcomeMessage = ChatMessage(
            content: "Hi! I'm your AI emergency assistant. I can help you with first aid instructions, emergency procedures, and health guidance. How can I help you today?",
            isFromUser: false,
            suggestions: ["Heart attack help", "Choking emergency", "Severe bleeding", "Stroke symptoms", "Fall injury"]
        )
        messages.append(welcomeMessage)
    }

    func sendMessage(_ content: String) {
        let userMessage = ChatMessage(content: content, isFromUser: true)
        messages.append(userMessage)

        processUserMessage(content)
    }

    private func processUserMessage(_ content: String) {
        isProcessing = true

        // Analyze user message for emergency type
        let emergencyType = analyzeEmergencyType(from: content)
        let response = generateResponse(for: emergencyType, userMessage: content)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let aiMessage = ChatMessage(
                content: response.content,
                isFromUser: false,
                emergencyType: emergencyType,
                actionRequired: response.actionRequired,
                suggestions: response.suggestions
            )

            self.messages.append(aiMessage)
            self.isProcessing = false

            if self.voiceEnabled {
                self.speakMessage(response.content)
            }
        }
    }

    private func analyzeEmergencyType(from message: String) -> EmergencyType? {
        let lowercaseMessage = message.lowercased()

        // Simple keyword matching - in a real app, this would use CoreML/NLP
        if lowercaseMessage.contains("heart") || lowercaseMessage.contains("chest pain") {
            return .heartAttack
        } else if lowercaseMessage.contains("choking") || lowercaseMessage.contains("can't breathe") {
            return .choking
        } else if lowercaseMessage.contains("bleeding") || lowercaseMessage.contains("blood") {
            return .bleeding
        } else if lowercaseMessage.contains("stroke") || lowercaseMessage.contains("face drooping") {
            return .stroke
        } else if lowercaseMessage.contains("fall") || lowercaseMessage.contains("fell") {
            return .fall
        } else if lowercaseMessage.contains("unconscious") || lowercaseMessage.contains("passed out") {
            return .unconscious
        } else if lowercaseMessage.contains("poison") || lowercaseMessage.contains("overdose") {
            return .poisoning
        } else if lowercaseMessage.contains("fire") || lowercaseMessage.contains("burn") {
            return .fire
        }

        return nil
    }

    private func generateResponse(for emergencyType: EmergencyType?, userMessage: String) -> (content: String, actionRequired: Bool, suggestions: [String]) {

        if let emergency = emergencyType {
            let instructions = emergencyResponses[emergency.rawValue] ?? ["Call 911 immediately", "Stay calm and follow basic first aid principles"]

            var response = "I detected this might be a \(emergency.rawValue) emergency. Here's what you should do:\n\n"

            for (index, instruction) in instructions.enumerated() {
                response += "\(index + 1). \(instruction)\n"
            }

            response += "\nRemember: When in doubt, call 911. Your safety is the priority."

            let suggestions = [
                "Call 911 now",
                "More details",
                "Prevention tips",
                "Different emergency"
            ]

            return (response, true, suggestions)
        } else {
            // General health advice or clarification
            let generalResponse = provideGeneralAdvice(for: userMessage)
            return (generalResponse.content, false, generalResponse.suggestions)
        }
    }

    private func provideGeneralAdvice(for message: String) -> (content: String, suggestions: [String]) {
        let lowercaseMessage = message.lowercased()

        if lowercaseMessage.contains("help") || lowercaseMessage.contains("emergency") {
            return (
                "I'm here to help with emergency situations. Can you tell me more specifically what's happening? Is someone injured, unconscious, or in immediate danger?",
                ["Heart emergency", "Breathing problems", "Injury", "Poisoning", "Someone is unconscious"]
            )
        } else if lowercaseMessage.contains("pain") {
            return (
                "Pain can indicate various conditions. For severe or sudden pain, especially chest pain, call 911. For other pain, can you describe the location and severity?",
                ["Chest pain", "Severe pain", "Abdominal pain", "Head injury"]
            )
        } else if lowercaseMessage.contains("breathing") {
            return (
                "Breathing difficulties can be serious. If someone can't breathe or is turning blue, call 911 immediately. Are they conscious and able to speak?",
                ["Can't breathe", "Choking", "Allergic reaction", "Asthma attack"]
            )
        } else {
            return (
                "I'm designed to help with emergency situations and first aid. Can you describe the emergency you're facing? If this is life-threatening, please call 911 immediately.",
                ["Medical emergency", "Injury", "Breathing problems", "Unconscious person", "Severe bleeding"]
            )
        }
    }

    // MARK: - Voice Features
    func startListening() {
        guard speechRecognizer?.isAvailable == true else { return }

        isListening = true

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }

        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let result = result {
                let spokenText = result.bestTranscription.formattedString

                if result.isFinal {
                    self?.sendMessage(spokenText)
                    self?.stopListening()
                }
            }

            if error != nil {
                self?.stopListening()
            }
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try? audioEngine.start()
    }

    func stopListening() {
        isListening = false
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
    }

    private func speakMessage(_ message: String) {
        let utterance = AVSpeechUtterance(string: message)
        utterance.voice = AVSpeechSynthesisVoice(language: currentLanguage)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        speechSynthesizer.speak(utterance)
    }

    func clearConversation() {
        messages.removeAll()
        addInitialMessage()
    }

    func exportConversation() -> String {
        var export = "SwiftAid Emergency Conversation\n"
        export += "Date: \(Date())\n\n"

        for message in messages {
            let sender = message.isFromUser ? "User" : "AI Assistant"
            export += "[\(sender)] \(message.content)\n\n"
        }

        return export
    }
}

extension AIAssistantManager: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        // Handle speech recognizer availability changes
    }
}
