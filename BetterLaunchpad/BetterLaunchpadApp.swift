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
        .windowLevel(.floating)

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

        // Arrow keys and Page Up/Down for pagination when main UI is active
        let arrowKeyCodes: Set<UInt16> = [123, 124, 125, 126] // left, right, down, up
        let pagingKeyCodes: Set<UInt16> = [116, 121] // PageUp, PageDown

        if (arrowKeyCodes.contains(event.keyCode) || pagingKeyCodes.contains(event.keyCode)) &&
            event.modifierFlags.intersection([.command, .option, .control]).isEmpty {

            // Ignore when Settings/About are active
            if let kw = NSApp.keyWindow, kw.identifier?.rawValue == "about" { return event }
            if UserDefaults.standard.bool(forKey: "settingsActive") { return event }

            let code = event.keyCode
            var dir: Int? = nil

            // If typing in a text view (search), only hijack when it won't disrupt typing:
            // - Empty field: always handle arrows/page keys for paging
            // - Left arrow at caret position 0: previous page
            // - Right arrow at caret at end: next page
            if let tv = NSApp.keyWindow?.firstResponder as? NSTextView {
                let text = tv.string as NSString
                let len = text.length
                let sel = tv.selectedRange()
                let caretAtStart = (sel.length == 0 && sel.location == 0)
                let caretAtEnd   = (sel.length == 0 && sel.location == len)

                if len == 0 {
                    // Empty input: allow paging for these keys
                    switch code {
                    case 124, 126, 121: dir = 1   // right/up/PageDown → next
                    case 123, 125, 116: dir = -1  // left/down/PageUp → previous
                    default: break
                    }
                } else {
                    // Non-empty: only page at bounds so caret navigation still works
                    switch code {
                    case 124: if caretAtEnd   { dir = 1 }
                    case 123: if caretAtStart { dir = -1 }
                    case 121: dir = 1 // PageDown
                    case 116: dir = -1 // PageUp
                    default: break // up/down inside text do nothing; leave to field
                    }
                }
            } else {
                // Not in a text field — free to page
                switch code {
                case 124, 126, 121: dir = 1   // right/up/PageDown → next
                case 123, 125, 116: dir = -1  // left/down/PageUp → previous
                default: break
                }
            }

            if let d = dir {
                NotificationCenter.default.post(name: .blWheel, object: nil, userInfo: ["dir": d])
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
    guard let window = NSApp.windows.first(where: { $0.isVisible }) else { return }

    window.styleMask = [.titled, .fullSizeContentView, .resizable]
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.toolbar = nil
    
    window.contentView?.wantsLayer = true
    window.contentView?.layer?.backgroundColor = NSColor.clear.cgColor

    window.isOpaque = false
    window.backgroundColor = NSColor.clear
    window.hasShadow = true

    window.ignoresMouseEvents = false

    window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
    window.level = .normal

    if let screen = window.screen ?? NSScreen.main {
        let fullFrame = screen.frame
        window.setFrame(fullFrame, display: true)
    }
    
    window.makeKeyAndOrderFront(nil)
    window.isMovableByWindowBackground = false

    window.standardWindowButton(.closeButton)?.isHidden = true
    window.standardWindowButton(.miniaturizeButton)?.isHidden = true
    window.standardWindowButton(.zoomButton)?.isHidden = true

    window.setFrameAutosaveName("LauncherMainWindow")

    window.hidesOnDeactivate = false
    window.canHide = false
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
