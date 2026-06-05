//
//  FavoritesModal.swift
//  BetterLaunchpad
//
//  Created by Radim Veselý on 08.12.2025.
//  Licensed under the MIT License.
//

import SwiftUI
import AppKit

private func fontWeight(from tag: Int) -> Font.Weight {
    switch tag {
    case 1: return .medium
    case 2: return .semibold
    case 3: return .bold
    default: return .regular
    }
}

private func nsFontWeight(from w: Font.Weight) -> NSFont.Weight {
    switch w {
    case .ultraLight: return .ultraLight
    case .thin: return .thin
    case .light: return .light
    case .regular: return .regular
    case .medium: return .medium
    case .semibold: return .semibold
    case .bold: return .bold
    case .heavy: return .heavy
    case .black: return .black
    default: return .regular
    }
}

private func fontForLabel(name: String, size: Double, weightTag: Int) -> Font {
    let weight = fontWeight(from: weightTag)
    if name == "System" {
        return .system(size: CGFloat(size), weight: weight)
    }
    let descriptor = NSFontDescriptor(fontAttributes: [
        .family: name,
        .traits: [NSFontDescriptor.TraitKey.weight: nsFontWeight(from: weight)]
    ])
    let nsf = NSFont(descriptor: descriptor, size: CGFloat(size)) ?? NSFont.systemFont(ofSize: CGFloat(size), weight: nsFontWeight(from: weight))
    return Font(nsf)
}

private func showInFinderThenRestore(path: String) {
    let esc = path
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
        NSApp.hide(nil)

        let script = """
        set _deadline to (current date) + 30

        tell application "System Events"
            if not (exists process "Finder") then
                tell application "Finder" to launch
                repeat until (exists process "Finder")
                    delay 0.1
                end repeat
            end if
        end tell

        tell application "Finder"
            activate
            reveal (POSIX file "\(esc)")
        end tell
        """

        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.launchPath = "/usr/bin/osascript"
            task.arguments = ["-e", script]
            do { try task.run() } catch { NSLog("ShowInFinder osascript failed: \(error.localizedDescription)") }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                NSApp.terminate(nil)
            }

            task.waitUntilExit()
        }
    }
}

private func showFinderGetInfo(for path: String) {
    let esc = path
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")

    NSApp.hide(nil)

    let script = """
    tell application "System Events"
        if not (exists process "Finder") then
            tell application "Finder" to launch
            repeat until (exists process "Finder")
                delay 0.1
            end repeat
        end if
    end tell

    tell application "Finder"
        set theItem to (POSIX file "\(esc)") as alias
        open information window of theItem
        activate
    end tell
    """

    DispatchQueue.global(qos: .userInitiated).async {
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        do { try task.run() } catch { NSLog("GetInfo osascript failed: \(error.localizedDescription)") }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            NSApp.terminate(nil)
        }

        task.waitUntilExit()
    }
}

struct FavoritesModal: View {
    @ObservedObject var favoritesManager = FavoritesManager.shared
    let allApps: [AppInfo]
    let iconSize: Double
    let onLaunch: () -> Void
    @Binding var isPresented: Bool
    @State private var closeHovering = false
    
    @AppStorage("labelFontSize") private var labelFontSize: Double = 12
    @AppStorage("labelFontWeight") private var labelFontWeight: Int = 0
    @AppStorage("labelFontName") private var labelFontName: String = "System"
    
    @AppStorage("blurEnabled") private var blurEnabled: Bool = true
    @AppStorage("materialRaw") private var materialRaw: Int = NSVisualEffectView.Material.hudWindow.rawValue
    @AppStorage("bgR") private var bgR: Double = 0.08
    @AppStorage("bgG") private var bgG: Double = 0.08
    @AppStorage("bgB") private var bgB: Double = 0.10
    @AppStorage("bgA") private var bgA: Double = 0.60
    
    private var favoriteApps: [AppInfo] {
        allApps.filter { favoritesManager.isFavorite($0.path) }
    }
    
    private let columns = [
        GridItem(.adaptive(minimum: 158), spacing: 28)
    ]

    private var modalIconSize: Double {
        min(max(iconSize * 0.82, 72), 88)
    }
    
    var body: some View {
        ZStack {
            VisualEffectView(
                material: blurEnabled ? (NSVisualEffectView.Material(rawValue: materialRaw) ?? .hudWindow) : .hudWindow,
                blendingMode: .behindWindow,
                state: .active
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            Color.black.opacity(0.08)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            LinearGradient(
                colors: [
                    Color(red: bgR, green: bgG, blue: bgB).opacity(max(bgA * 0.58, 0.26)),
                    Color.black.opacity(0.14),
                    Color.yellow.opacity(0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            RadialGradient(
                colors: [
                    Color.yellow.opacity(0.08),
                    Color.white.opacity(0.018),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 20,
                endRadius: 460
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            VStack(spacing: 0) {
                header

                Divider()
                    .opacity(0.20)
                    .padding(.horizontal, 28)

                if favoriteApps.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 28) {
                            ForEach(favoriteApps) { app in
                                FavoriteAppCell(
                                    app: app,
                                    iconSize: modalIconSize,
                                    onLaunch: onLaunch
                                )
                            }
                        }
                        .padding(.horizontal, 36)
                        .padding(.top, 28)
                        .padding(.bottom, 38)
                    }
                }
            }
        }
        .frame(width: 860, height: 580)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.46), radius: 38, x: 0, y: 20)
        .environment(\.colorScheme, .dark)
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.yellow.opacity(0.82),
                                Color.orange.opacity(0.62)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 46, height: 46)

                Image(systemName: "star.fill")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundColor(.white)
            }
            .shadow(color: Color.orange.opacity(0.28), radius: 12, y: 6)

            HStack(spacing: 10) {
                Text(String(localized: "Favorites"))
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.55), radius: 2, x: 0, y: 1)

                Text("\(favoriteApps.count)")
                    .font(.caption.weight(.bold))
                    .monospacedDigit()
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.10))
                    )
            }

            Spacer()

            Button(action: { isPresented = false }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(closeHovering ? 0.98 : 0.82))
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.black.opacity(closeHovering ? 0.52 : 0.34))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color.white.opacity(closeHovering ? 0.24 : 0.12), lineWidth: 1)
                            )
                    )
                    .shadow(color: .black.opacity(closeHovering ? 0.26 : 0.12), radius: closeHovering ? 10 : 4, y: closeHovering ? 5 : 2)
            }
            .buttonStyle(.plain)
            .scaleEffect(closeHovering ? 1.08 : 1.0)
            .onHover { hovering in
                withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                    closeHovering = hovering
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 24)
        .padding(.bottom, 18)
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 116, height: 116)

                Circle()
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    .frame(width: 116, height: 116)

                Image(systemName: "star.slash")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 6) {
                Text(String(localized: "No favorites yet"))
                    .font(.title3.weight(.semibold))

                Text(String(localized: "Right-click any app and select 'Add to Favorites'"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 28)
    }
}

struct FavoriteAppCell: View {
    let app: AppInfo
    let iconSize: Double
    let onLaunch: () -> Void
    
    @State private var hovering = false
    @State private var pressed = false
    @ObservedObject var favoritesManager = FavoritesManager.shared
    
    @AppStorage("labelFontSize") private var labelFontSize: Double = 12
    @AppStorage("labelFontWeight") private var labelFontWeight: Int = 0
    @AppStorage("labelFontName") private var labelFontName: String = "System"
    @AppStorage("iconHoverEffect") private var iconHoverEffect: Int = 0
    
    @AppStorage("labelR") private var labelR: Double = 0.0
    @AppStorage("labelG") private var labelG: Double = 0.0
    @AppStorage("labelB") private var labelB: Double = 0.0
    @AppStorage("labelA") private var labelA: Double = 1.0
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(hovering ? Color.white.opacity(0.16) : Color.white.opacity(0.075))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(hovering ? Color.white.opacity(0.26) : Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(hovering ? 0.22 : 0.12), radius: hovering ? 18 : 10, y: hovering ? 10 : 5)

                VStack(spacing: 10) {
                    ZStack {
                        if hovering && glowOpacity > 0 {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.white.opacity(glowOpacity),
                                            Color.white.opacity(glowOpacity * 0.28),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: iconSize * 0.8
                                    )
                                )
                                .frame(width: iconSize + glowExpansion, height: iconSize + glowExpansion)
                        }
                        
                        Image(nsImage: app.icon)
                            .resizable()
                            .frame(width: iconSize, height: iconSize)
                            .clipShape(RoundedRectangle(cornerRadius: iconSize > 80 ? 18 : 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: iconSize > 80 ? 18 : 16, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(hovering ? 0.30 : 0.10),
                                                Color.white.opacity(hovering ? 0.10 : 0.05)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: hovering ? 1.5 : 0.5
                                    )
                            )
                            .shadow(
                                color: Color.black.opacity(hovering ? hoverShadowOpacity : 0.15),
                                radius: hovering ? hoverShadowRadius : 8,
                                x: 0,
                                y: hovering ? hoverShadowY : 4
                            )
                            .scaleEffect(pressed ? 0.95 : (hovering ? hoverScale : 1.0))
                            .offset(y: hovering ? hoverOffsetY : 0)
                            .rotation3DEffect(
                                .degrees(hovering ? hoverTiltDegrees : 0),
                                axis: (x: 1, y: -1, z: 0),
                                perspective: 0.65
                            )
                    }
                    .frame(width: iconSize + 24, height: iconSize + 24)

                    Text(app.name)
                        .font(fontForLabel(name: labelFontName, size: labelFontSize, weightTag: labelFontWeight))
                        .foregroundColor(Color(red: labelR, green: labelG, blue: labelB).opacity(labelA))
                        .lineLimit(1)
                        .frame(maxWidth: iconSize + 34)
                        .shadow(color: Color.black.opacity(0.24), radius: 1, x: 0, y: 1)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Button {
                    favoritesManager.removeFavorite(app.path)
                } label: {
                    Image(systemName: "star.slash.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 26, height: 26)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.13))
                        )
                }
                .buttonStyle(.plain)
                .opacity(hovering ? 1 : 0)
                .scaleEffect(hovering ? 1 : 0.86)
                .padding(8)
                .help(String(localized: "Remove from Favorites"))
            }
            .frame(width: iconSize + 84, height: iconSize + 82)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .onHover { hovering = $0 }
            .onTapGesture {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    pressed = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        pressed = false
                    }
                    NSWorkspace.shared.open(URL(fileURLWithPath: app.path))
                    onLaunch()
                }
            }
            .contextMenu {
                Button {
                    favoritesManager.removeFavorite(app.path)
                } label: {
                    Label(String(localized: "Remove from Favorites"), systemImage: "star.slash")
                }
                
                Divider()
                
                Button {
                    showInFinderThenRestore(path: app.path)
                } label: {
                    Label(String(localized: "Show in Finder"), systemImage: "folder")
                }
                
                Button {
                    showFinderGetInfo(for: app.path)
                } label: {
                    Label(String(localized: "Get Info"), systemImage: "info.circle")
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.82), value: hovering)
        .animation(.spring(response: 0.2, dampingFraction: 0.9), value: pressed)
    }

    private var hoverScale: CGFloat {
        switch iconHoverEffect {
        case 1: return 1.04
        case 2: return 1.15
        case 3: return 1.07
        case 4: return 1.12
        case 5: return 1.02
        default: return 1.08
        }
    }

    private var hoverOffsetY: CGFloat {
        switch iconHoverEffect {
        case 1: return -8
        case 4: return -5
        default: return 0
        }
    }

    private var hoverTiltDegrees: Double {
        iconHoverEffect == 3 ? 10 : 0
    }

    private var glowOpacity: Double {
        switch iconHoverEffect {
        case 1: return 0.08
        case 2: return 0.10
        case 3: return 0.14
        case 4: return 0.18
        case 5: return 0
        default: return 0.15
        }
    }

    private var glowExpansion: CGFloat {
        switch iconHoverEffect {
        case 2: return 28
        case 4: return 30
        default: return 20
        }
    }

    private var hoverShadowOpacity: Double {
        switch iconHoverEffect {
        case 1: return 0.32
        case 5: return 0.18
        default: return 0.25
        }
    }

    private var hoverShadowRadius: CGFloat {
        switch iconHoverEffect {
        case 1: return 18
        case 2: return 16
        case 5: return 10
        default: return 15
        }
    }

    private var hoverShadowY: CGFloat {
        switch iconHoverEffect {
        case 1: return 14
        case 5: return 5
        default: return 8
        }
    }
}
