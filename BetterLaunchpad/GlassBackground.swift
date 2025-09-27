//
//  GlassBackground.swift
//  BetterLaunchpad
//
//  Created by Radim Veselý on 19.09.2025.
//

import SwiftUI
import AppKit

struct GlassBackground: View {
    var material: NSVisualEffectView.Material
    var tint: Color
    var opacity: Double
    var followsActive: Bool = true

    var body: some View {
        // Glass effect with more transparency and color tint
        VisualEffectView(
            material: material, // Use the selected material from settings
            blendingMode: .behindWindow,
            state: followsActive ? .followsWindowActiveState : .active
        )
        .opacity(0.7) // Make it more transparent
        .overlay(
            // Very subtle color tint for glass effect
            tint.opacity(0.4)
                .allowsHitTesting(false)
        )
        .background(Color.clear)
        .ignoresSafeArea(.all)
        .allowsHitTesting(false)
    }
}

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    var state: NSVisualEffectView.State

    init(material: NSVisualEffectView.Material = .sidebar,
         blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
         state: NSVisualEffectView.State = .active) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
    }

    func makeNSView(context: Context) -> NSVisualEffectView {
        let effectView = NSVisualEffectView()

        // Core settings for glass effect
        effectView.material = material
        effectView.blendingMode = blendingMode
        effectView.state = state

        // Critical settings for transparency to work
        effectView.wantsLayer = true
        effectView.isEmphasized = false

        // Force the view to be transparent
        effectView.appearance = NSAppearance(named: .aqua)

        // Ensure the effect view fills its container
        effectView.autoresizingMask = [.width, .height]

        return effectView
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}
