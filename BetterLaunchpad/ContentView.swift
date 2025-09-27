//
//  ContentView.swift
//  BetterLaunchpad
//
//  Created by Radim Veselý on 17.09.2025.
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

// MARK: - Model

struct AppInfo: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    let icon: NSImage
}

final class AppModel: ObservableObject {
    @Published var apps: [AppInfo] = []
    init() { loadApps() }

    func loadApps() {
        // Search in these root directories
        let roots = [
            "/Applications",
            NSHomeDirectory() + "/Applications",
            "/System/Applications" // for Utilities etc.
        ]

        var items: [AppInfo] = []
        var seenPaths = Set<String>() // deduplication by full path

        let fm = FileManager.default

        for root in roots {
            let rootURL = URL(fileURLWithPath: root)

            // Recursive enumerator through folders, skip hidden files, don't go into packages (.app)
            if let e = fm.enumerator(
                at: rootURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) {
                for case let url as URL in e {
                    // filter only .app files
                    guard url.pathExtension == "app" else { continue }
                    let path = url.path
                    guard !seenPaths.contains(path) else { continue }
                    seenPaths.insert(path)

                    let name = url.deletingPathExtension().lastPathComponent
                    let icon = NSWorkspace.shared.icon(forFile: path)
                    icon.size = NSSize(width: 64, height: 64)

                    items.append(AppInfo(name: name, path: path, icon: icon))
                }
            }
        }

        // sort alphabetically
        items.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        DispatchQueue.main.async { self.apps = items }
    }
}

struct ContentView: View {
    @StateObject var model = AppModel()

    @State private var query = ""

    @FocusState private var searchFocused: Bool

    @AppStorage("cols") private var cols: Int = 7
    @AppStorage("rows") private var rows: Int = 5
    @AppStorage("iconSize") private var iconSize: Double = 96
    @AppStorage("materialRaw") private var materialRaw: Int = NSVisualEffectView.Material.hudWindow.rawValue

    @AppStorage("blurEnabled") private var blurEnabled: Bool = true
    @AppStorage("bgR") private var bgR: Double = 0.08
    @AppStorage("bgG") private var bgG: Double = 0.08
    @AppStorage("bgB") private var bgB: Double = 0.10
    @AppStorage("bgA") private var bgA: Double = 0.60

    @AppStorage("labelFontSize") private var labelFontSize: Double = 12
    @AppStorage("labelFontWeight") private var labelFontWeight: Int = 0
    @AppStorage("labelFontName") private var labelFontName: String = "System"

    var body: some View {
        ZStack {
            if blurEnabled {
                GlassBackground(
                    material: NSVisualEffectView.Material(rawValue: materialRaw) ?? .hudWindow,
                    tint: Color(red: bgR, green: bgG, blue: bgB),
                    opacity: bgA,
                    followsActive: true
                )
            } else {
                Color(red: bgR, green: bgG, blue: bgB)
                    .opacity(bgA)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                // Search section with enhanced spacing
                VStack(spacing: 0) {
                    Spacer().frame(height: 24)

                    HStack {
                        Spacer()
                        GlassSearchBar(
                            text: $query,
                            placeholder: String(localized: "search_placeholder")
                        ) { }
                        .focused($searchFocused)
                        Spacer()
                    }

                    Spacer().frame(height: 32)
                }

                // Grid / remaining area with improved spacing
                AppPagerView(
                    apps: filteredApps,
                    cols: cols,
                    rows: rows,
                    iconSize: iconSize,
                    onLaunch: { NSApp.terminate(nil) }
                )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
        }
        .frame(minWidth: 880, minHeight: 560)
        .onAppear {
            // Set initial focus when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                searchFocused = true
            }
        }
    }

    var filteredApps: [AppInfo] {
        guard !query.isEmpty else { return model.apps }
        return model.apps.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
}

struct AppPagerView: View {
    let apps: [AppInfo]
    let cols: Int
    let rows: Int
    let iconSize: Double
    let onLaunch: () -> Void

    @State private var page = 0
    @GestureState private var drag: CGFloat = 0

    // wheel state
    @State private var wheelMonitor: Any?
    @State private var lastWheelChange: TimeInterval = 0
    @State private var wheelAcc: CGFloat = 0
    private let wheelThrottle: TimeInterval = 0.06
    private let wheelStep: CGFloat = 6               // how many precise delta units ≈ one page step

    private var perPage: Int { max(cols * rows, 1) }
    private var pages: [[AppInfo]] {
        stride(from: 0, to: apps.count, by: perPage).map {
            Array(apps[$0 ..< min($0 + perPage, apps.count)])
        }
    }

    private func pageForward() {
        guard !pages.isEmpty else { return }
        page = (page + 1) % pages.count
    }
    private func pageBackward() {
        guard !pages.isEmpty else { return }
        page = (page - 1 + pages.count) % pages.count
    }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                ForEach(pages.indices, id: \.self) { i in
                    pageView(pages[i])
                        .opacity(i == page ? 1 : 0)
                        .scaleEffect(i == page ? 1.0 : 0.95)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: page)
                }
            }
            // Enhanced page indicators
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { i in
                    let isActive = (i == page)

                    ZStack {
                        // Background circle
                        Circle()
                            .fill(Color.white.opacity(isActive ? 0.9 : 0.3))
                            .frame(width: isActive ? 14 : 10, height: isActive ? 14 : 10)

                        // Inner glow for active indicator
                        if isActive {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.white.opacity(0.8),
                                            Color.white.opacity(0.4),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 8
                                    )
                                )
                                .frame(width: 16, height: 16)
                        }
                    }
                    .shadow(
                        color: Color.black.opacity(isActive ? 0.3 : 0.15),
                        radius: isActive ? 4 : 2,
                        y: isActive ? 2 : 1
                    )
                    .scaleEffect(isActive ? 1.0 : 0.9)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isActive)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            page = i
                        }
                    }
                }
            }
            .padding(.bottom, 16)
        }
        .gesture(
            DragGesture(minimumDistance: 20)
                .updating($drag) { value, state, _ in state = value.translation.width }
                .onEnded { value in
                    if value.translation.width < -40 { pageForward() }
                    if value.translation.width >  40 { pageBackward() }
                }
        )
        .onReceive(NotificationCenter.default.publisher(for: .blWheel)) { note in
            guard let dir = note.userInfo?["dir"] as? Int else { return }
            // Note: UP ⇒ forward (next page)
            if dir > 0 { pageForward() } else { pageBackward() }
        }
        .onChange(of: pages.count) { _, newCount in
            if newCount == 0 { page = 0 }
            else { page = (page % newCount + newCount) % newCount }
        }
    }

    @ViewBuilder
    private func pageView(_ pageApps: [AppInfo]) -> some View {
        GeometryReader { proxy in
            let W: CGFloat = proxy.size.width
            let H: CGFloat = proxy.size.height
            // --- layout tuning ---
            let cellPadX: CGFloat = 46
            let cellPadY: CGFloat = 58

            let cellWidth:  CGFloat = iconSize + cellPadX
            let cellHeight: CGFloat = iconSize + cellPadY

            let baseHSpacing: CGFloat = 50
            let maxHSpacing:  CGFloat = 72
            let baseVSpacing: CGFloat = 42
            let maxVSpacing:  CGFloat = 60

            let padX:       CGFloat = 8
            let padYBase:   CGFloat = 44
            let bottomPad:  CGFloat = 58

            // number of rows/columns per page
            let rowsCount = min(rows, Int(ceil(Double(pageApps.count) / Double(max(cols,1)))))
            let colsCount = max(min(cols, pageApps.count), 1)

            // available dimensions
            let targetWidth  = max(0, W - padX * 2)
            let availableH   = max(0, H - (padYBase + bottomPad))

            // HORIZONTALLY: calculate spacing to nicely fill the width
            let hSpacing: CGFloat = {
                guard colsCount > 1 else { return 0 }
                let need = (targetWidth - CGFloat(colsCount) * cellWidth) / CGFloat(colsCount - 1)
                return max(baseHSpacing, min(maxHSpacing, need))
            }()

            // Cílová výška vyplnění – posuneme grid níž a víc „rozsadíme“ řádky
            let targetFill: CGFloat = 0.78 // 0.5=center, 0.78=lower
            let targetHeight = max(0, availableH * targetFill)

            // VERTICALLY: calculate spacing to distribute items nicely
            let vSpacing: CGFloat = {
                guard rowsCount > 1 else { return 0 }
                // When we have fewer rows, use more generous spacing to prevent bottom alignment
                let spacingMultiplier: CGFloat = rowsCount <= 5 ? 1.3 : 1.0
                let adjustedBaseSpacing = baseVSpacing * spacingMultiplier
                let adjustedMaxSpacing = maxVSpacing * spacingMultiplier

                let need = (targetHeight - CGFloat(rowsCount) * cellHeight) / CGFloat(rowsCount - 1)
                return max(adjustedBaseSpacing, min(adjustedMaxSpacing, need))
            }()

            // resulting grid dimensions
            let desiredWidth  = CGFloat(colsCount) * cellWidth  + CGFloat(max(colsCount - 1, 0)) * hSpacing
            let desiredHeight = CGFloat(rowsCount) * cellHeight + CGFloat(max(rowsCount - 1, 0)) * vSpacing

            let gridWidth  = min(targetWidth,  desiredWidth)
            let gridHeight = min(availableH,   desiredHeight)

            // Adjust alignment based on number of rows - center when fewer rows, slight downward bias when more
            let bias: CGFloat = rowsCount <= 5 ? 0.35 : 0.65  // 0.35 = above center, 0.65 = below center
            let extraTop = max(0, (availableH - gridHeight) * bias)

            // columns
            let gridCols: [GridItem] = Array(
                repeating: GridItem(.fixed(cellWidth), spacing: hSpacing),
                count: max(colsCount, 1)
            )

            HStack {
                Spacer(minLength: 0)
                LazyVGrid(columns: gridCols, alignment: .center, spacing: vSpacing) {
                    ForEach(pageApps) { app in
                        AppIconCell(app: app, iconSize: iconSize, onLaunch: onLaunch)
                            .frame(width: cellWidth, height: cellHeight, alignment: .top)
                    }
                }
                .frame(width: gridWidth, height: gridHeight, alignment: .center)
                .padding(.top, padYBase + extraTop)
                .padding(.bottom, bottomPad)
                Spacer(minLength: 0)
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
            removal:   .move(edge: .leading).combined(with: .opacity).combined(with: .scale(scale: 1.05))
        ))
    }
}

struct AppIconCell: View {
    let app: AppInfo
    let iconSize: Double
    let onLaunch: () -> Void
    @State private var hovering = false
    @State private var pressed = false

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
                // Enhanced background glow effect
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
                        .animation(.easeInOut(duration: 0.3), value: hovering)
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
        .padding(8)
    }
}

// MARK: - Show Finder
private func showInFinderThenRestore(path: String) {
    let esc = path
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")

    // Briefly hide window so Finder gets focus
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

            // Terminate app – osascript will continue running without us
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                NSApp.terminate(nil)
            }

            task.waitUntilExit() // optional; doesn't matter that app is already terminating
        }
    }
}

// MARK: - Show Info
private func showFinderGetInfo(for path: String) {
    let esc = path
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")

    // Lightly hide window so Info doesn't stay behind you
    NSApp.hide(nil)

    let script = """
    -- Ensure Finder is running
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

        // Immediately terminate app (small delay helps with focus transitions)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            NSApp.terminate(nil)
        }

        task.waitUntilExit()
    }
}


#Preview {
    ContentView()
}
