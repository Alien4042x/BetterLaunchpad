//
//  AboutView.swift
//  BetterLaunchpad
//
//  Created by Radim Veselý on 19.09.2025.
//

import SwiftUI

struct AboutView: View {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1001"

    var body: some View {
        VStack(spacing: 20) {
            // App icon and title
            VStack(spacing: 12) {
                if let nsImg = NSImage(named: "AppIcon") {
                    Image(nsImage: nsImg)
                        .resizable()
                        .frame(width: 64, height: 64)
                }
                
                Text(String(localized: "BetterLaunchpad"))
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Version \(version) (Build \(build))")
                    .font(.title3)
                    .foregroundColor(.secondary)
                Text("By Alien4042x")
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .italic()
            }

            Divider()

            // Description
            VStack(spacing: 16) {
                Text(String(localized: "A modern, customizable application launcher for macOS"))
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
                    .frame(maxWidth: 420, alignment: .center)
                
                VStack(alignment: .leading, spacing: 8) {
                    FeatureRow(icon: "grid", title: String(localized: "Customizable Grid"),
                               description: String(localized: "Flexible layouts with adjustable rows and columns"))
                    FeatureRow(icon: "sparkles", title: String(localized: "Glass Effects"),
                               description: String(localized: "Beautiful transparency and blur effects"))
                    FeatureRow(icon: "magnifyingglass", title: String(localized: "Smart Search"),
                               description: String(localized: "Quick application search and launch"))
                    FeatureRow(icon: "paintbrush", title: String(localized: "Theming"),
                               description: String(localized: "Custom colors and fonts for personalization"))
                }
            }
            .padding(.horizontal, 24)

            Divider()

            // Credits
            VStack(spacing: 8) {
                Text(String(localized: "Created with ❤️ for macOS"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()

                Text(String(localized: "© 2025 BetterLaunchpad"))
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }

            Spacer()
        }
        .padding(30)
        .frame(width: 400, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.blue)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    AboutView()
}
