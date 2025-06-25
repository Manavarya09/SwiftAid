//
//  AIAssistantView.swift
//  SwiftAid
//
//  Created by AI Assistant on 6/25/25.
//

import SwiftUI

struct AIAssistantView: View {
    @StateObject private var aiManager = AIAssistantManager()
    @State private var messageText = ""
    @State private var showingVoiceSettings = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection

                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(aiManager.messages) { message in
                                ChatMessageView(message: message)
                                    .id(message.id)
                            }

                            if aiManager.isProcessing {
                                HStack {
                                    LoadingView()
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: aiManager.messages.count) { _ in
                        if let lastMessage = aiManager.messages.last {
                            withAnimation(.easeOut(duration: 0.5)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Input section
                inputSection
            }
            .background(GlassmorphicBackground().ignoresSafeArea())
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: HStack {
                    Button(action: { showingVoiceSettings = true }) {
                        Image(systemName: "gear")
                            .font(.title3)
                    }

                    Button(action: { aiManager.clearConversation() }) {
                        Image(systemName: "trash")
                            .font(.title3)
                    }
                }
            )
        }
        .sheet(isPresented: $showingVoiceSettings) {
            VoiceSettingsView(aiManager: aiManager)
        }
    }

    private var headerSection: some View {
        GlassCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Emergency AI Assistant")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("Ask me about first aid, emergencies, and health")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if aiManager.voiceEnabled {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                }
            }
            .padding()
        }
        .padding(.horizontal)
        .padding(.top)
    }

    private var inputSection: some View {
        VStack(spacing: 12) {
            // Quick suggestions
            if let lastMessage = aiManager.messages.last, !lastMessage.suggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(lastMessage.suggestions, id: \.self) { suggestion in
                            Button(suggestion) {
                                aiManager.sendMessage(suggestion)
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // Input bar
            HStack(spacing: 12) {
                HStack {
                    TextField("Ask about emergencies, first aid...", text: $messageText, axis: .vertical)
                        .textFieldStyle(PlainTextFieldStyle())
                        .lineLimit(1...4)

                    if !messageText.isEmpty {
                        Button(action: {
                            sendMessage()
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .cornerRadius(25)

                // Voice input button
                Button(action: {
                    if aiManager.isListening {
                        aiManager.stopListening()
                    } else {
                        aiManager.startListening()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(aiManager.isListening ? Color.red : Color.blue)
                            .frame(width: 44, height: 44)
                            .scaleEffect(aiManager.isListening ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.1), value: aiManager.isListening)

                        Image(systemName: aiManager.isListening ? "stop.fill" : "mic.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
                .shadow(color: (aiManager.isListening ? Color.red : Color.blue).opacity(0.4), radius: 5)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        aiManager.sendMessage(messageText)
        messageText = ""
    }
}

struct ChatMessageView: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                userMessageView
            } else {
                assistantMessageView
                Spacer()
            }
        }
    }

    private var userMessageView: some View {
        Text(message.content)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(20, corners: [.topLeft, .topRight, .bottomLeft])
            .font(.body)
    }

    private var assistantMessageView: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: "brain.head.profile")
                    .font(.caption)
                    .foregroundColor(.blue)
            }

            // Message content
            VStack(alignment: .leading, spacing: 8) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20, corners: [.topLeft, .topRight, .bottomRight])
                    .font(.body)

                if message.actionRequired {
                    Text("⚠️ Immediate action may be required")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                }

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
            }
        }
    }
}

struct VoiceSettingsView: View {
    @ObservedObject var aiManager: AIAssistantManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "speaker.wave.3")
                        .font(.largeTitle)
                        .foregroundColor(.blue)

                    Text("Voice Settings")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Configure how the AI assistant speaks to you during emergencies")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 16) {
                    GlassCard {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Voice Responses")
                                    .font(.headline)

                                Text("Hear spoken instructions during emergencies")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: $aiManager.voiceEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                        }
                        .padding()
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Language")
                                .font(.headline)

                            Picker("Language", selection: $aiManager.currentLanguage) {
                                Text("English (US)").tag("en-US")
                                Text("Spanish").tag("es-ES")
                                Text("French").tag("fr-FR")
                                Text("German").tag("de-DE")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        .padding()
                    }
                }

                Spacer()

                Button("Test Voice") {
                    // Test voice functionality
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .fontWeight(.semibold)
                .cornerRadius(15)
            }
            .padding()
            .navigationTitle("Voice Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
    }
}

extension RoundedRectangle {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some Shape {
        clipShape(RoundedCorners(radius: radius, corners: corners))
    }
}

struct RoundedCorners: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
