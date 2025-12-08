//
//  FavoritesModal.swift
//  BetterLaunchpad
//
//  Created by Radim Veselý on 08.12.2025.
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
        GridItem(.adaptive(minimum: 140), spacing: 40)
    ]
    
    private let modalIconSize: Double = 80
    
    var body: some View {
        ZStack {
            Color(red: bgR, green: bgG, blue: bgB)
                .opacity(0.6)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            
            VStack(spacing: 0) {
                HStack {
                    Text(String(localized: "Favorites"))
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                    
                    Spacer()
                    
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 40)
                .padding(.top, 28)
                .padding(.bottom, 21)
                
                if favoriteApps.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "star.slash")
                            .font(.system(size: 64))
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text(String(localized: "No favorites yet"))
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(String(localized: "Right-click any app and select 'Add to Favorites'"))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 40) {
                            ForEach(favoriteApps) { app in
                                FavoriteAppCell(
                                    app: app,
                                    iconSize: modalIconSize,
                                    onLaunch: onLaunch
                                )
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.vertical, 32)
                    }
                    .offset(y: -15)
                }
            }
        }
        .frame(width: 900, height: 650)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
        .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 10)
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
    
    @AppStorage("labelR") private var labelR: Double = 0.0
    @AppStorage("labelG") private var labelG: Double = 0.0
    @AppStorage("labelB") private var labelB: Double = 0.0
    @AppStorage("labelA") private var labelA: Double = 1.0
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                if hovering {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: iconSize * 0.8
                            )
                        )
                        .frame(width: iconSize + 20, height: iconSize + 20)
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
                                        Color.white.opacity(hovering ? 0.3 : 0.1),
                                        Color.white.opacity(hovering ? 0.1 : 0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: hovering ? 1.5 : 0.5
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(hovering ? 0.25 : 0.15),
                        radius: hovering ? 15 : 8,
                        x: 0,
                        y: hovering ? 8 : 4
                    )
                    .scaleEffect(pressed ? 0.95 : (hovering ? 1.08 : 1.0))
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: hovering)
                    .animation(.spring(response: 0.2, dampingFraction: 0.9), value: pressed)
            }
            .frame(width: iconSize + 20, height: iconSize + 20)
            .onHover { hovering = $0 }
            .onTapGesture {
                pressed = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    pressed = false
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
            
            Text(app.name)
                .font(fontForLabel(name: labelFontName, size: labelFontSize, weightTag: labelFontWeight))
                .foregroundColor(Color(red: labelR, green: labelG, blue: labelB).opacity(labelA))
                .lineLimit(1)
                .frame(maxWidth: iconSize + 24)
                .shadow(
                    color: Color.black.opacity(0.3),
                    radius: 1,
                    x: 0,
                    y: 1
                )
                .scaleEffect(hovering ? 1.02 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: hovering)
        }
        .frame(width: iconSize + 40, height: iconSize + 60)
        .padding(8)
    }
}
