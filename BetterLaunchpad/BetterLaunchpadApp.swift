//
//  BetterLaunchpadApp.swift
//  BetterLaunchpad
//
//  Created by Radim Veselý on 17.09.2025.
//

import SwiftUI
import AppKit

// Custom window class to handle focus better
class BetterLaunchpadWindow: NSWindow {
    override func becomeKey() {
        super.becomeKey()
        // Post notification when window becomes key
        NotificationCenter.default.post(name: .windowDidBecomeKey, object: self)
    }

    override func resignKey() {
        super.resignKey()
        // Don't minimize when losing focus
    }

    override func mouseDown(with event: NSEvent) {
        // Handle clicks on empty space - don't minimize, just restore focus
        super.mouseDown(with: event)
        NotificationCenter.default.post(name: .restoreSearchFocus, object: nil)
    }
}

extension Notification.Name {
    static let windowDidBecomeKey = Notification.Name("WindowDidBecomeKey")
    static let restoreSearchFocus = Notification.Name("RestoreSearchFocus")
}

@main
struct BetterLaunchpadApp: App {

    init() {
        // Force language detection on app start
        setupLocalization()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear { makeWindowNice(); installGlobalEscToQuit(); installGlobalWheelToPager() }
        }
        .windowStyle(.plain)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button(action: {
                    // Open our custom about window
                    openAboutWindow()
                }) {
                    Label(String(localized: "About BetterLaunchpad"), systemImage: "info.circle")
                }
            }
        }

        Settings {
            SettingsView()
                .padding(20)
                .frame(minWidth: 720)
        }

        // About window
        Window("About BetterLaunchpad", id: "about") {
            AboutView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

// MARK: - Localization Setup

private func setupLocalization() {
    // Get system language
    let preferredLanguages = Locale.preferredLanguages
    print("System preferred languages: \(preferredLanguages)")

    // Check if Czech is in preferred languages
    if preferredLanguages.contains(where: { $0.hasPrefix("cs") }) {
        print("Czech language detected")
    }

    // Force bundle to recognize localizations
    if let path = Bundle.main.path(forResource: "cs", ofType: "lproj"),
       let bundle = Bundle(path: path) {
        print("Czech localization bundle found: \(bundle)")
    }
}

// MARK: - About Window Helper

private func openAboutWindow() {
    // Try to find existing about window
    if let aboutWindow = NSApp.windows.first(where: { $0.identifier?.rawValue == "about" }) {
        aboutWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        return
    }

    // Create and show about window programmatically
    DispatchQueue.main.async {
        let aboutWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        aboutWindow.title = "About BetterLaunchpad"
        aboutWindow.identifier = NSUserInterfaceItemIdentifier("about")
        aboutWindow.isReleasedWhenClosed = false
        aboutWindow.contentView = NSHostingView(rootView: AboutView())
        aboutWindow.center()
        aboutWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Window styling

private var escEventMonitor: Any?
private var wheelEventMonitor: Any?
private var globalWheelAcc: CGFloat = 0

private func installGlobalEscToQuit() {
    guard escEventMonitor == nil else { return }
    escEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
        // Only handle when app is active
        guard NSApp.isActive else { return event }

        // ESC
        if event.keyCode == 53 {
            // If Settings is active, close that window
            if UserDefaults.standard.bool(forKey: "settingsActive") {
                NSApp.keyWindow?.performClose(nil)
                return nil
            }

            // If About is key, close About instead of quitting
            if let kw = NSApp.keyWindow, kw.identifier?.rawValue == "about" {
                kw.performClose(nil)
                return nil
            }

            // Otherwise quit the app
            NSApp.terminate(nil)
            return nil
        }

        // CMD+F to restore search focus (only when main window is key)
        if event.keyCode == 3 && event.modifierFlags.contains(.command) {
            if let kw = NSApp.keyWindow, kw.identifier?.rawValue != "about" {
                DispatchQueue.main.async {
                    guard let w = NSApp.keyWindow, w.isVisible else { return }
                    NotificationCenter.default.post(name: .restoreSearchFocus, object: nil)
                }
                return nil
            }
        }

        return event
    }
}

private func installGlobalWheelToPager() {
    guard wheelEventMonitor == nil else { return }
    wheelEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { ev in
        guard NSApp.isActive,
              let kw = NSApp.keyWindow,
              kw.identifier?.rawValue != "about",
              !UserDefaults.standard.bool(forKey: "settingsActive")
        else { return ev }

        var dy = ev.scrollingDeltaY != 0 ? ev.scrollingDeltaY : -ev.scrollingDeltaX
        if ev.isDirectionInvertedFromDevice { dy = -dy }
        if ev.hasPreciseScrollingDeltas {
            let step: CGFloat = 10
            globalWheelAcc += dy
            while abs(globalWheelAcc) >= step {
                let dir = globalWheelAcc > 0 ? 1 : -1
                NotificationCenter.default.post(name: .blWheel, object: nil, userInfo: ["dir": dir])
                globalWheelAcc += dir > 0 ? -step : step
            }
        } else {
            let dir = dy > 0 ? 1 : (dy < 0 ? -1 : 0)
            if dir != 0 {
                NotificationCenter.default.post(name: .blWheel, object: nil, userInfo: ["dir": dir])
            }
        }
        return ev
    }
}

private func removeEventMonitors() {
    if let m = escEventMonitor { NSEvent.removeMonitor(m); escEventMonitor = nil }
    if let m = wheelEventMonitor { NSEvent.removeMonitor(m); wheelEventMonitor = nil }
}

private func isAuxVisible() -> Bool {
    // Settings signalizuješ přes @AppStorage("settingsActive")
    let settingsOpen = UserDefaults.standard.bool(forKey: "settingsActive")
    let aboutOpen = NSApp.windows.contains { $0.identifier?.rawValue == "about" }
    return settingsOpen || aboutOpen
}

private func installAllMonitorsIfNeeded() {
    guard !isAuxVisible(), escEventMonitor == nil, wheelEventMonitor == nil else { return }
    installGlobalEscToQuit()
    installGlobalWheelToPager()
}

extension Notification.Name {
    static let blWheel = Notification.Name("BLMouseWheel")
}

func makeWindowNice() {
    // Grab the visible main window (safer than windows.first)
    guard let window = NSApp.windows.first(where: { $0.isVisible }) else { return }

    // Use a titled window (visually titlebar-less) so it CAN become key and accept focus
    window.styleMask.insert([.titled, .resizable, .fullSizeContentView])
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.toolbar = nil

    // Allow translucency/blur through the window
    window.isOpaque = false
    window.backgroundColor = NSColor.clear
    window.hasShadow = true

    // Critical for glass effect to work
    window.ignoresMouseEvents = false

    // Behavior: fill to visible frame (menu bar & dock stay visible)
    window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    window.level = .normal

    if let screen = window.screen ?? NSScreen.main {
        let vf = screen.visibleFrame
        window.setFrame(vf, display: true)
    }
    window.makeKeyAndOrderFront(nil)
    window.isMovableByWindowBackground = false

    // Hide traffic lights (safety: if present)
    window.standardWindowButton(.closeButton)?.isHidden = true
    window.standardWindowButton(.miniaturizeButton)?.isHidden = true
    window.standardWindowButton(.zoomButton)?.isHidden = true

    window.setFrameAutosaveName("LauncherMainWindow")

    // Prevent window from minimizing when clicking on empty space
    window.hidesOnDeactivate = false
    window.canHide = false

    // (acceptsMouseMovedEvents and async focus block removed)

}

// MARK: - NSVisualEffect (blur)

struct TransparentBlurView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    var blending: NSVisualEffectView.BlendingMode = .behindWindow
    var followsActive: Bool = true

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blending
        v.state = followsActive ? .followsWindowActiveState : .active
        v.wantsLayer = true

        // Ensure the view is properly configured for transparency
        v.appearance = NSAppearance(named: .aqua)

        // Force transparency for glass effect
        v.alphaValue = 1.0
        v.isEmphasized = false

        return v
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blending
        nsView.state = followsActive ? .followsWindowActiveState : .active
    }
}
