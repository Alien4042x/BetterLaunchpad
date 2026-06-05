//
//  AboutView.swift
//  BetterLaunchpad
//
//  Created by Radim Veselý on 19.09.2025.
//  Licensed under the MIT License.
//

import SwiftUI
import AppKit

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isAnimating = false

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1001"
    }

    var body: some View {
        ZStack {
            VisualEffectView(
                material: .hudWindow,
                blendingMode: .behindWindow,
                state: .active
            )
            .ignoresSafeArea()

            LaunchpadParticleField()
                .opacity(0.40)
                .blendMode(.screen)

            VStack(spacing: 22) {
                header

                VStack(spacing: 10) {
                    AboutFeatureRow(
                        icon: "square.grid.3x3.fill",
                        title: String(localized: "Customizable Grid"),
                        description: String(localized: "Flexible layouts with adjustable rows and columns")
                    )

                    AboutFeatureRow(
                        icon: "magnifyingglass",
                        title: String(localized: "Smart Search"),
                        description: String(localized: "Quick application search and launch")
                    )

                    AboutFeatureRow(
                        icon: "star.fill",
                        title: String(localized: "Favorites"),
                        description: String(localized: "Quick access to your favorite apps")
                    )

                    AboutFeatureRow(
                        icon: "globe",
                        title: String(localized: "HTML Backgrounds"),
                        description: String(localized: "Custom animated backgrounds with HTML themes")
                    )
                }

                HStack(spacing: 10) {
                    AboutInfoPill(icon: "person.fill", text: "Alien4042x")
                    AboutInfoPill(icon: "number", text: "Build \(build)")
                    AboutInfoPill(icon: "paintbrush.fill", text: String(localized: "Theming"))
                }

                Spacer(minLength: 0)

                footer
            }
            .padding(.horizontal, 34)
            .padding(.vertical, 30)
        }
        .frame(width: 500, height: 600)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.32),
                                Color.cyan.opacity(0.20),
                                Color.white.opacity(0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 132, height: 132)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: Color.blue.opacity(0.22), radius: 26, y: 14)
                    .scaleEffect(isAnimating ? 1.02 : 0.98)

                appIcon
                    .frame(width: 86, height: 86)
                    .shadow(color: Color.black.opacity(0.28), radius: 14, y: 8)
                    .scaleEffect(isAnimating ? 1.0 : 0.94)
            }

            VStack(spacing: 5) {
                Text(String(localized: "BetterLaunchpad"))
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.primary)

                Text(String(localized: "A modern, customizable application launcher for macOS"))
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text("v\(version)")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
            }

            Text(String(localized: "Liquid Glass Effects"))
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                )
        }
    }

    @ViewBuilder
    private var appIcon: some View {
        if let image = NSImage(named: "AppIcon") {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 58, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white)
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button {
                if let url = URL(string: "https://github.com/alien4042x") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Label("GitHub", systemImage: "link")
                    .frame(width: 128)
            }
            .buttonStyle(.bordered)

            Button {
                dismiss()
                NSApp.keyWindow?.performClose(nil)
            } label: {
                Text("Close")
                    .frame(width: 128)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return, modifiers: [])
        }
    }
}

private struct AboutFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.34))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

private struct AboutInfoPill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(text)
                .font(.caption.weight(.medium))
                .lineLimit(1)
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

private struct LaunchpadParticleField: View {
    private let particles = LaunchpadParticle.samples

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSinceReferenceDate

                for particle in particles {
                    let phase = elapsed * particle.speed + particle.phase
                    let x = particle.origin.x * size.width + cos(phase) * particle.range.width
                    let y = particle.origin.y * size.height + sin(phase * 0.8) * particle.range.height
                    let rect = CGRect(
                        x: x - particle.size / 2,
                        y: y - particle.size / 2,
                        width: particle.size,
                        height: particle.size
                    )

                    context.drawLayer { layer in
                        layer.addFilter(.blur(radius: particle.blur))
                        layer.fill(
                            Path(roundedRect: rect, cornerRadius: particle.size * 0.24),
                            with: .color(particle.color.opacity(particle.opacity))
                        )
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

private struct LaunchpadParticle: Identifiable {
    let id: Int
    let origin: CGPoint
    let range: CGSize
    let size: CGFloat
    let blur: CGFloat
    let speed: Double
    let phase: Double
    let opacity: Double
    let color: Color

    static let samples: [LaunchpadParticle] = [
        LaunchpadParticle(id: 0, origin: CGPoint(x: 0.16, y: 0.18), range: CGSize(width: 28, height: 18), size: 24, blur: 8, speed: 0.34, phase: 0.2, opacity: 0.30, color: .blue),
        LaunchpadParticle(id: 1, origin: CGPoint(x: 0.82, y: 0.16), range: CGSize(width: 24, height: 20), size: 18, blur: 7, speed: 0.44, phase: 1.1, opacity: 0.28, color: .cyan),
        LaunchpadParticle(id: 2, origin: CGPoint(x: 0.38, y: 0.34), range: CGSize(width: 18, height: 26), size: 14, blur: 5, speed: 0.50, phase: 2.2, opacity: 0.22, color: .white),
        LaunchpadParticle(id: 3, origin: CGPoint(x: 0.88, y: 0.50), range: CGSize(width: 28, height: 22), size: 28, blur: 10, speed: 0.28, phase: 3.4, opacity: 0.18, color: .blue),
        LaunchpadParticle(id: 4, origin: CGPoint(x: 0.14, y: 0.72), range: CGSize(width: 26, height: 24), size: 20, blur: 8, speed: 0.38, phase: 4.2, opacity: 0.24, color: .cyan),
        LaunchpadParticle(id: 5, origin: CGPoint(x: 0.68, y: 0.78), range: CGSize(width: 22, height: 16), size: 16, blur: 6, speed: 0.46, phase: 5.0, opacity: 0.20, color: .blue),
        LaunchpadParticle(id: 6, origin: CGPoint(x: 0.48, y: 0.92), range: CGSize(width: 36, height: 10), size: 22, blur: 9, speed: 0.30, phase: 2.0, opacity: 0.16, color: .white)
    ]
}

#Preview {
    AboutView()
}
