//
//  GlassmorphicComponents.swift
//  SwiftAid
//
//  Created by AI Assistant on 6/25/25.
//

import SwiftUI

// MARK: - Glassmorphic Background
struct GlassmorphicBackground: View {
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(.systemBackground).opacity(0.1),
                    Color(.systemRed).opacity(0.1),
                    Color(.systemBlue).opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Animated blob shapes
            GeometryReader { geometry in
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.red.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.3)
                        .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: geometry.size)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.blue.opacity(0.2), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.7)
                        .animation(.easeInOut(duration: 10).repeatForever(autoreverses: true), value: geometry.size)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.orange.opacity(0.15), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 120
                            )
                        )
                        .frame(width: 250, height: 250)
                        .position(x: geometry.size.width * 0.6, y: geometry.size.height * 0.2)
                        .animation(.easeInOut(duration: 12).repeatForever(autoreverses: true), value: geometry.size)
                }
            }
        }
        .blur(radius: 1)
    }
}

// MARK: - Glass Card
struct GlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 20
    var borderWidth: CGFloat = 1

    init(cornerRadius: CGFloat = 20, borderWidth: CGFloat = 1, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
    }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: borderWidth
                            )
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Neumorphic Button
struct NeumorphicButton<Content: View>: View {
    let content: Content
    let action: () -> Void
    @State private var isPressed = false

    init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: action) {
            content
                .padding()
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.systemGray6))
                            .shadow(
                                color: isPressed ? Color.clear : Color.black.opacity(0.2),
                                radius: isPressed ? 0 : 10,
                                x: isPressed ? 0 : -5,
                                y: isPressed ? 0 : -5
                            )
                            .shadow(
                                color: isPressed ? Color.clear : Color.white.opacity(0.7),
                                radius: isPressed ? 0 : 10,
                                x: isPressed ? 0 : 5,
                                y: isPressed ? 0 : 5
                            )

                        if isPressed {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(.systemGray6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                        .blur(radius: 1)
                                        .offset(x: 2, y: 2)
                                        .mask(RoundedRectangle(cornerRadius: 15).fill(LinearGradient(gradient: Gradient(colors: [Color.black, Color.clear]), startPoint: .topLeading, endPoint: .bottomTrailing)))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        .blur(radius: 1)
                                        .offset(x: -2, y: -2)
                                        .mask(RoundedRectangle(cornerRadius: 15).fill(LinearGradient(gradient: Gradient(colors: [Color.clear, Color.black]), startPoint: .topLeading, endPoint: .bottomTrailing)))
                                )
                        }
                    }
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { _ in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
        } onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }
    }
}

// MARK: - Emergency Button
struct EmergencyButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isPulsing = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(color, lineWidth: 2)
                        )
                        .scaleEffect(isPulsing ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)

                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if title.contains("Emergency") || title.contains("911") {
                isPulsing = true
            }
        }
    }
}

// MARK: - Vitals Card
struct VitalsCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let isNormal: Bool

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)

                    Spacer()

                    Circle()
                        .fill(isNormal ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(alignment: .bottom) {
                        Text(value)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text(unit)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Animated Heart Rate
struct AnimatedHeartRate: View {
    let heartRate: Double
    @State private var isBeating = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .font(.title2)
                .foregroundColor(.red)
                .scaleEffect(isBeating ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 60.0 / heartRate).repeatForever(autoreverses: true), value: isBeating)
                .onAppear {
                    isBeating = true
                }

            Text("\(Int(heartRate))")
                .font(.title2)
                .fontWeight(.bold)

            Text("BPM")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    @State private var rotation = 0.0

    var body: some View {
        VStack(spacing: 20) {
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(Color.red, lineWidth: 4)
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(rotation))
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: rotation)
                .onAppear {
                    rotation = 360
                }

            Text("Processing...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Emergency Status Badge
struct EmergencyStatusBadge: View {
    let status: EmergencyStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(status.rawValue.capitalized)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.2))
        .cornerRadius(8)
    }

    private var statusColor: Color {
        switch status {
        case .detecting: return .orange
        case .confirmed: return .red
        case .responding: return .blue
        case .resolved: return .green
        case .falseAlarm: return .gray
        }
    }
}

// MARK: - Custom Modifiers
extension View {
    func glassmorphic(cornerRadius: CGFloat = 20) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    func emergencyGlow() -> some View {
        self
            .shadow(color: .red.opacity(0.5), radius: 10, x: 0, y: 0)
            .shadow(color: .red.opacity(0.3), radius: 20, x: 0, y: 0)
    }
}
