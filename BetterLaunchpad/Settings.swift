//
//  Settings.swift
//  BetterLaunchpad
//
//  Created by Radim Veselý on 17.09.2025.
//

import SwiftUI
import AppKit

struct SettingsView: View {
    @AppStorage("cols") private var cols: Int = 7
    @AppStorage("rows") private var rows: Int = 5
    @AppStorage("iconSize") private var iconSize: Double = 96
    @AppStorage("materialRaw") private var materialRaw: Int = NSVisualEffectView.Material.hudWindow.rawValue

    @AppStorage("blurEnabled") private var blurEnabled: Bool = false
    @AppStorage("bgR") private var bgR: Double = 0.08
    @AppStorage("bgG") private var bgG: Double = 0.08
    @AppStorage("bgB") private var bgB: Double = 0.10
    @AppStorage("bgA") private var bgA: Double = 0.60

    @AppStorage("labelFontSize") private var labelFontSize: Double = 12
    // 0=regular,1=medium,2=semibold,3=bold
    @AppStorage("labelFontWeight") private var labelFontWeight: Int = 0
    @AppStorage("labelFontName") private var labelFontName: String = "System"

    // Label color RGBA (default black)
    @AppStorage("labelR") private var labelR: Double = 1.0
    @AppStorage("labelG") private var labelG: Double = 1.0
    @AppStorage("labelB") private var labelB: Double = 1.0
    @AppStorage("labelA") private var labelA: Double = 1.0

    @AppStorage("settingsActive") private var settingsActive: Bool = false

    private let materials: [(String, NSVisualEffectView.Material)] = [
        ("hudWindow", .hudWindow),
        ("popover", .popover),
        ("menu", .menu),
        ("sidebar", .sidebar),
        ("titlebar", .titlebar),
        ("underWindowBackground", .underWindowBackground),
    ]

    private let fontFamilies: [String] = NSFontManager.shared.availableFontFamilies.sorted()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "settings")).font(.title3).bold()

            Stepper("\(String(localized: "columns")): \(cols)", value: $cols, in: 3...8)
            Stepper("\(String(localized: "rows")): \(rows)", value: $rows, in: 2...5)

            HStack {
                Text(String(localized: "icon_size"))
                Slider(value: $iconSize, in: 40...128)
                Text("\(Int(iconSize)) pt")
                    .foregroundColor(.secondary)
            }

            // Only show blur material picker when blur is enabled
            if blurEnabled {
                Picker(String(localized: "blur_material"), selection: $materialRaw) {
                    ForEach(materials, id: \.1.rawValue) { item in
                        Text(item.0).tag(item.1.rawValue)
                    }
                }
                .pickerStyle(.menu)
            }

            // Background appearance
            Group {
                Toggle(String(localized: "Enable blur"), isOn: $blurEnabled)

                // Only show opacity slider when blur is disabled
                if !blurEnabled {
                    HStack {
                        Text(String(localized: "Background opacity"))
                        Slider(value: $bgA, in: 0...1)
                        Text(String(format: "%.0f%%", bgA * 100)).foregroundColor(.secondary)
                    }
                }

                // Simple color palette
                Text(String(localized: "Background color")).font(.headline)
                HStack(spacing: 8) {
                    ColorSwatch(name: String(localized: "Graphite"), r: 0.2, g: 0.2, b: 0.25, current: (bgR, bgG, bgB)) { (r,g,b) in bgR=r; bgG=g; bgB=b }
                    ColorSwatch(name: String(localized: "Blue"),     r: 0.2, g: 0.4, b: 0.8, current: (bgR, bgG, bgB)) { (r,g,b) in bgR=r; bgG=g; bgB=b }
                    ColorSwatch(name: String(localized: "Purple"),   r: 0.5, g: 0.3, b: 0.7, current: (bgR, bgG, bgB)) { (r,g,b) in bgR=r; bgG=g; bgB=b }
                    ColorSwatch(name: String(localized: "Green"),    r: 0.2, g: 0.6, b: 0.4, current: (bgR, bgG, bgB)) { (r,g,b) in bgR=r; bgG=g; bgB=b }
                    ColorSwatch(name: String(localized: "Orange"),   r: 0.8, g: 0.5, b: 0.2, current: (bgR, bgG, bgB)) { (r,g,b) in bgR=r; bgG=g; bgB=b }
                }

                // Fine-tune RGB
                VStack(spacing: 6) {
                    HStack { Text("R"); Slider(value: $bgR, in: 0...1); Text(String(format: "%.2f", bgR)).foregroundColor(.secondary) }
                    HStack { Text("G"); Slider(value: $bgG, in: 0...1); Text(String(format: "%.2f", bgG)).foregroundColor(.secondary) }
                    HStack { Text("B"); Slider(value: $bgB, in: 0...1); Text(String(format: "%.2f", bgB)).foregroundColor(.secondary) }
                }

                // Live preview swatch - brighter like font color preview
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: bgR, green: bgG, blue: bgB))
                    .frame(height: 28)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            }

            // Label font settings
            Group {
                Text(String(localized: "Label font")).font(.headline)
                Picker(String(localized: "Family"), selection: $labelFontName) {
                    Text(String(localized: "System")).tag("System")
                    ForEach(fontFamilies, id: \.self) { fam in
                        Text(fam).tag(fam)
                    }
                }
                .pickerStyle(.menu)
                HStack {
                    Text(String(localized: "Size"))
                    Slider(value: $labelFontSize, in: 9...18)
                    Text("\(Int(labelFontSize)) pt").foregroundColor(.secondary)
                }
                Picker(String(localized: "Weight"), selection: $labelFontWeight) {
                    Text(String(localized: "Regular")).tag(0)
                    Text(String(localized: "Medium")).tag(1)
                    Text(String(localized: "Semibold")).tag(2)
                    Text(String(localized: "Bold")).tag(3)
                }
                .pickerStyle(.segmented)

                Text(String(localized: "Label color")).font(.headline)
                HStack(spacing: 8) {
                    ColorSwatch(name: String(localized: "Black"), r: 0, g: 0, b: 0, current: (labelR, labelG, labelB)) { (r,g,b) in labelR=r; labelG=g; labelB=b }
                    ColorSwatch(name: String(localized: "White"), r: 1, g: 1, b: 1, current: (labelR, labelG, labelB)) { (r,g,b) in labelR=r; labelG=g; labelB=b }
                    ColorSwatch(name: String(localized: "Gray"),  r: 0.5, g: 0.5, b: 0.5, current: (labelR, labelG, labelB)) { (r,g,b) in labelR=r; labelG=g; labelB=b }
                    ColorSwatch(name: String(localized: "Blue"),  r: 0.12, g: 0.36, b: 0.92, current: (labelR, labelG, labelB)) { (r,g,b) in labelR=r; labelG=g; labelB=b }
                }
                VStack(spacing: 6) {
                    HStack { Text("R"); Slider(value: $labelR, in: 0...1); Text(String(format: "%.2f", labelR)).foregroundColor(.secondary) }
                    HStack { Text("G"); Slider(value: $labelG, in: 0...1); Text(String(format: "%.2f", labelG)).foregroundColor(.secondary) }
                    HStack { Text("B"); Slider(value: $labelB, in: 0...1); Text(String(format: "%.2f", labelB)).foregroundColor(.secondary) }
                    HStack { Text(String(localized: "Opacity")); Slider(value: $labelA, in: 0...1); Text(String(format: "%.0f%%", labelA*100)).foregroundColor(.secondary) }
                }
            }

            // Reset to defaults
            Button(String(localized: "Reset to defaults")) {
                cols = 7; rows = 5; iconSize = 96
                materialRaw = NSVisualEffectView.Material.hudWindow.rawValue
                blurEnabled = false
                bgR = 0.08; bgG = 0.08; bgB = 0.10; bgA = 0.60
                labelFontSize = 12; labelFontWeight = 0; labelFontName = "System"
                labelR = 1.0; labelG = 1.0; labelB = 1.0; labelA = 1.0
            }
            .buttonStyle(.bordered)

            Divider()

            Text(String(localized: "tips"))
                .font(.headline)
            Text(String(localized: "tips_content"))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
            Text(String(localized: "Changes apply instantly. Press Esc to quit."))
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .onAppear { settingsActive = true }
        .onDisappear { settingsActive = false }
    }
}

private struct ColorSwatch: View {
    let name: String
    let r: Double
    let g: Double
    let b: Double
    let current: (Double, Double, Double)
    let onPick: (Double, Double, Double) -> Void

    var body: some View {
        Button(action: { onPick(r,g,b) }) {
            Circle()
                .fill(Color(red: r, green: g, blue: b))
                .frame(width: 20, height: 20)
                // Base subtle ring for visibility
                .overlay(
                    Circle().stroke(baseBorderColor, lineWidth: 1).opacity(isSelected ? 0 : 1)
                )
                // Selection ring matches original thickness, adaptive contrast
                .overlay(
                    Circle().stroke(selectionBorderColor, lineWidth: 2).opacity(isSelected ? 1 : 0)
                )
                .overlay(
                    Circle().stroke(Color.black.opacity(0.6), lineWidth: isSelected && r == 1 && g == 1 && b == 1 ? 2 : 0)
                )
                .scaleEffect(isSelected ? 1.12 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSelected)
                .help(name)
        }
        .buttonStyle(.plain)
    }

    private var isSelected: Bool {
        abs(current.0 - r) < 0.01 && abs(current.1 - g) < 0.01 && abs(current.2 - b) < 0.01
    }

    private var luminance: Double {
        0.2126*r + 0.7152*g + 0.0722*b
    }

    private var baseBorderColor: Color {
        luminance > 0.7 ? Color.black.opacity(0.25) : Color.white.opacity(0.2)
    }

    private var selectionBorderColor: Color {
        luminance > 0.7 ? Color.black.opacity(0.7) : Color.white.opacity(0.9)
    }
}
