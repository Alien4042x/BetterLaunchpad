//
//  Settings.swift
//  BetterLaunchpad
//
//  Created by Radim Veselý on 17.09.2025.
//  Licensed under the MIT License.
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
    @AppStorage("labelFontWeight") private var labelFontWeight: Int = 0
    @AppStorage("labelFontName") private var labelFontName: String = "System"
    @AppStorage("iconHoverEffect") private var iconHoverEffect: Int = 0

    @AppStorage("labelR") private var labelR: Double = 1.0
    @AppStorage("labelG") private var labelG: Double = 1.0
    @AppStorage("labelB") private var labelB: Double = 1.0
    @AppStorage("labelA") private var labelA: Double = 1.0

    @AppStorage("backgroundMode") private var backgroundMode: Int = 0
    @AppStorage("selectedHTML") private var selectedHTML: String = ""

    @AppStorage("settingsActive") private var settingsActive: Bool = false

    @StateObject private var themeManager = HTMLThemeManager.shared
    @State private var selectedSection = 0

    private let materials: [(String, NSVisualEffectView.Material)] = [
        ("hudWindow", .hudWindow),
        ("popover", .popover),
        ("menu", .menu),
        ("sidebar", .sidebar),
        ("titlebar", .titlebar),
        ("underWindowBackground", .underWindowBackground),
    ]

    private let fontFamilies: [String] = NSFontManager.shared.availableFontFamilies.sorted()

    private let sections: [(title: LocalizedStringKey, icon: String)] = [
        ("Layout", "square.grid.3x3.fill"),
        ("Background", "photo.fill"),
        ("Icons", "app.fill"),
        ("Labels", "textformat"),
        ("Advanced", "gearshape.fill")
    ]

    var body: some View {
        HStack(spacing: 0) {
            sidebar

            Divider()

            VStack(alignment: .leading, spacing: 0) {
                header

                ScrollView {
                    currentSection
                        .padding(.horizontal, 22)
                        .padding(.bottom, 22)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: 780, height: 620)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear(perform: activateSettings)
        .onDisappear { settingsActive = false }
        .onChange(of: backgroundMode) { _, newValue in
            handleBackgroundModeChange(newValue)
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "settings"))
                .font(.title3.weight(.bold))
                .padding(.horizontal, 14)
                .padding(.top, 16)
                .padding(.bottom, 8)

            ForEach(sections.indices, id: \.self) { index in
                Button {
                    selectedSection = index
                } label: {
                    HStack(spacing: 9) {
                        Image(systemName: sections[index].icon)
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 18)
                        Text(sections[index].title)
                            .font(.subheadline.weight(selectedSection == index ? .semibold : .regular))
                        Spacer(minLength: 0)
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(selectedSection == index ? Color.accentColor.opacity(0.16) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Text(String(localized: "Changes apply instantly. Press Esc to quit."))
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(14)
        }
        .frame(width: 168)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.36))
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(sections[selectedSection].title)
                    .font(.title2.weight(.bold))
                Text(sectionSubtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                resetToDefaults()
            } label: {
                Label(String(localized: "Reset to defaults"), systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
    }

    @ViewBuilder
    private var currentSection: some View {
        switch selectedSection {
        case 1:
            backgroundSection
        case 2:
            iconsSection
        case 3:
            labelsSection
        case 4:
            advancedSection
        default:
            layoutSection
        }
    }

    private var layoutSection: some View {
        VStack(spacing: 14) {
            SettingsGroup(title: String(localized: "Grid"), icon: "square.grid.3x3.fill") {
                SettingsStepperRow(title: String(localized: "columns"), value: $cols, range: 3...8)
                SettingsStepperRow(title: String(localized: "rows"), value: $rows, range: 2...5)

                SettingsSliderRow(
                    title: String(localized: "icon_size"),
                    value: $iconSize,
                    range: 40...128,
                    valueText: "\(Int(iconSize)) pt"
                )
            }

            SettingsGroup(title: String(localized: "Preview"), icon: "eye.fill") {
                HStack(spacing: 14) {
                    iconPreview

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(cols) x \(rows)")
                            .font(.headline)
                        Text("\(cols * rows) \(String(localized: "apps per page"))")
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }
        }
    }

    private var backgroundSection: some View {
        VStack(spacing: 14) {
            SettingsGroup(title: String(localized: "Background Type"), icon: "photo.fill") {
                Picker(String(localized: "Background Type"), selection: $backgroundMode) {
                    Text(String(localized: "Glass")).tag(0)
                    Text(String(localized: "HTML")).tag(1)
                }
                .pickerStyle(.segmented)

                if backgroundMode == 1 {
                    SettingsSliderRow(
                        title: String(localized: "HTML Background opacity"),
                        value: $bgA,
                        range: 0...1,
                        valueText: String(format: "%.0f%%", bgA * 100)
                    )
                }
            }

            if backgroundMode == 0 {
                glassBackgroundControls
            } else {
                htmlBackgroundControls
            }
        }
    }

    private var glassBackgroundControls: some View {
        SettingsGroup(title: String(localized: "Glass"), icon: "circle.hexagongrid.fill") {
            Toggle(String(localized: "Enable blur"), isOn: $blurEnabled)

            if blurEnabled {
                Picker(String(localized: "blur_material"), selection: $materialRaw) {
                    ForEach(materials, id: \.1.rawValue) { item in
                        Text(item.0).tag(item.1.rawValue)
                    }
                }
                .pickerStyle(.menu)
            } else {
                SettingsSliderRow(
                    title: String(localized: "Background opacity"),
                    value: $bgA,
                    range: 0...1,
                    valueText: String(format: "%.0f%%", bgA * 100)
                )
            }

            colorPalette(title: String(localized: "Background color"), current: (bgR, bgG, bgB)) { r, g, b in
                bgR = r
                bgG = g
                bgB = b
            }

            VStack(spacing: 8) {
                SettingsSliderRow(title: "R", value: $bgR, range: 0...1, valueText: String(format: "%.2f", bgR))
                SettingsSliderRow(title: "G", value: $bgG, range: 0...1, valueText: String(format: "%.2f", bgG))
                SettingsSliderRow(title: "B", value: $bgB, range: 0...1, valueText: String(format: "%.2f", bgB))
            }

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(red: bgR, green: bgG, blue: bgB))
                .frame(height: 30)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.white.opacity(0.28), lineWidth: 1)
                )
        }
    }

    private var htmlBackgroundControls: some View {
        SettingsGroup(title: String(localized: "Select HTML Background"), icon: "globe") {
            htmlThemeList
        }
    }

    private var iconsSection: some View {
        VStack(spacing: 14) {
            SettingsGroup(title: String(localized: "Icon hover effect"), icon: "sparkles") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                    ForEach(0..<6, id: \.self) { effect in
                        Button {
                            iconHoverEffect = effect
                        } label: {
                            HoverEffectOptionCard(
                                title: hoverEffectName(for: effect),
                                description: hoverEffectDescription(for: effect),
                                icon: hoverEffectIcon(for: effect),
                                isSelected: iconHoverEffect == effect
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            SettingsGroup(title: String(localized: "Preview"), icon: "app.fill") {
                HStack(spacing: 16) {
                    iconPreview

                    VStack(alignment: .leading, spacing: 4) {
                        Text(hoverEffectName)
                            .font(.headline)
                        Text(String(localized: "The original default is Liquid Glow."))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }
        }
    }

    private var labelsSection: some View {
        VStack(spacing: 14) {
            SettingsGroup(title: String(localized: "Label font"), icon: "textformat") {
                Picker(String(localized: "Family"), selection: $labelFontName) {
                    Text(String(localized: "System")).tag("System")
                    ForEach(fontFamilies, id: \.self) { family in
                        Text(family).tag(family)
                    }
                }
                .pickerStyle(.menu)

                SettingsSliderRow(
                    title: String(localized: "Size"),
                    value: $labelFontSize,
                    range: 9...18,
                    valueText: "\(Int(labelFontSize)) pt"
                )

                Picker(String(localized: "Weight"), selection: $labelFontWeight) {
                    Text(String(localized: "Regular")).tag(0)
                    Text(String(localized: "Medium")).tag(1)
                    Text(String(localized: "Semibold")).tag(2)
                    Text(String(localized: "Bold")).tag(3)
                }
                .pickerStyle(.segmented)
            }

            SettingsGroup(title: String(localized: "Label color"), icon: "paintpalette.fill") {
                colorPalette(title: String(localized: "Label color"), current: (labelR, labelG, labelB)) { r, g, b in
                    labelR = r
                    labelG = g
                    labelB = b
                }

                VStack(spacing: 8) {
                    SettingsSliderRow(title: "R", value: $labelR, range: 0...1, valueText: String(format: "%.2f", labelR))
                    SettingsSliderRow(title: "G", value: $labelG, range: 0...1, valueText: String(format: "%.2f", labelG))
                    SettingsSliderRow(title: "B", value: $labelB, range: 0...1, valueText: String(format: "%.2f", labelB))
                    SettingsSliderRow(title: String(localized: "Opacity"), value: $labelA, range: 0...1, valueText: String(format: "%.0f%%", labelA * 100))
                }
            }
        }
    }

    private var advancedSection: some View {
        VStack(spacing: 14) {
            SettingsGroup(title: String(localized: "Theme Library"), icon: "folder.fill") {
                HStack {
                    Button(String(localized: "Refresh Themes")) {
                        themeManager.refreshThemes()
                    }
                    .buttonStyle(.bordered)

                    Button(String(localized: "Open Custom Themes Folder")) {
                        NSWorkspace.shared.open(getCustomThemesDirectory())
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            themeManager.refreshThemes()
                        }
                    }
                    .buttonStyle(.bordered)

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Custom Themes Location:"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(getCustomThemesDirectory().path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
            }

            SettingsGroup(title: String(localized: "tips"), icon: "lightbulb.fill") {
                Text(String(localized: "tips_content"))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var htmlThemeList: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !themeManager.isInitialized {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                    Text(String(localized: "Loading themes..."))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 160, alignment: .center)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                    ForEach(themeManager.availableThemes, id: \.self) { theme in
                        Button {
                            selectedHTML = theme
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: selectedHTML == theme ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedHTML == theme ? .accentColor : .secondary)

                                Text(theme)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(selectedHTML == theme ? Color.accentColor.opacity(0.14) : Color(nsColor: .controlBackgroundColor).opacity(0.35))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var iconPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.88), Color.cyan.opacity(0.70)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 58, height: 58)

            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 25, weight: .semibold))
                .foregroundStyle(.white)
        }
        .shadow(color: Color.black.opacity(0.18), radius: 10, y: 5)
    }

    private func colorPalette(title: String, current: (Double, Double, Double), onPick: @escaping (Double, Double, Double) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            HStack(spacing: 9) {
                ColorSwatch(name: String(localized: "Graphite"), r: 0.2, g: 0.2, b: 0.25, current: current, onPick: onPick)
                ColorSwatch(name: String(localized: "Blue"), r: 0.2, g: 0.4, b: 0.8, current: current, onPick: onPick)
                ColorSwatch(name: String(localized: "Purple"), r: 0.5, g: 0.3, b: 0.7, current: current, onPick: onPick)
                ColorSwatch(name: String(localized: "Green"), r: 0.2, g: 0.6, b: 0.4, current: current, onPick: onPick)
                ColorSwatch(name: String(localized: "Orange"), r: 0.8, g: 0.5, b: 0.2, current: current, onPick: onPick)
                ColorSwatch(name: String(localized: "Black"), r: 0, g: 0, b: 0, current: current, onPick: onPick)
                ColorSwatch(name: String(localized: "White"), r: 1, g: 1, b: 1, current: current, onPick: onPick)
                ColorSwatch(name: String(localized: "Gray"), r: 0.5, g: 0.5, b: 0.5, current: current, onPick: onPick)
            }
        }
    }

    private var sectionSubtitle: String {
        switch selectedSection {
        case 1: return String(localized: "Choose glass or animated HTML backgrounds.")
        case 2: return String(localized: "Pick how app icons react when you hover.")
        case 3: return String(localized: "Tune app label typography and color.")
        case 4: return String(localized: "Manage theme folders and general controls.")
        default: return String(localized: "Set grid density and icon size.")
        }
    }

    private var hoverEffectIcon: String {
        hoverEffectIcon(for: iconHoverEffect)
    }

    private func hoverEffectIcon(for effect: Int) -> String {
        switch effect {
        case 1: return "arrow.up"
        case 2: return "plus.magnifyingglass"
        case 3: return "rotate.3d"
        case 4: return "arrow.up.and.down"
        case 5: return "circle"
        default: return "sparkles"
        }
    }

    private var hoverEffectName: String {
        hoverEffectName(for: iconHoverEffect)
    }

    private func hoverEffectName(for effect: Int) -> String {
        switch effect {
        case 1: return String(localized: "Lift")
        case 2: return String(localized: "Zoom")
        case 3: return String(localized: "Tilt")
        case 4: return String(localized: "Bounce")
        case 5: return String(localized: "Minimal")
        default: return String(localized: "Liquid Glow")
        }
    }

    private var hoverEffectDescription: String {
        hoverEffectDescription(for: iconHoverEffect)
    }

    private func hoverEffectDescription(for effect: Int) -> String {
        switch effect {
        case 1: return String(localized: "Raises the icon with a cleaner shadow and less glow.")
        case 2: return String(localized: "Focuses on a stronger zoom while keeping the icon centered.")
        case 3: return String(localized: "Adds a subtle 3D tilt for a more playful launcher feel.")
        case 4: return String(localized: "Uses a springy bounce for a more energetic hover.")
        case 5: return String(localized: "Keeps hover feedback restrained for a calmer desktop.")
        default: return String(localized: "Keeps the current glass glow with a soft scale animation.")
        }
    }

    private func activateSettings() {
        settingsActive = true

        if !themeManager.isInitialized {
            print("Initializing themes from Settings...")
        }

        if backgroundMode == 1 && selectedHTML.isEmpty && !themeManager.availableThemes.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if self.selectedHTML.isEmpty && !self.themeManager.availableThemes.isEmpty {
                    self.selectedHTML = self.themeManager.availableThemes.first ?? ""
                    print("Auto-selected default HTML theme: \(self.selectedHTML)")
                }
            }
        }
    }

    private func handleBackgroundModeChange(_ newValue: Int) {
        if newValue == 1 && selectedHTML.isEmpty {
            if !themeManager.availableThemes.isEmpty {
                selectedHTML = themeManager.availableThemes.first ?? ""
            } else {
                backgroundMode = 0
                bgR = 0.2
                bgG = 0.2
                bgB = 0.25
            }
        }
    }

    private func resetToDefaults() {
        cols = 7
        rows = 5
        iconSize = 96
        materialRaw = NSVisualEffectView.Material.hudWindow.rawValue
        blurEnabled = false
        bgR = 0.08
        bgG = 0.08
        bgB = 0.10
        bgA = 0.60
        labelFontSize = 12
        labelFontWeight = 0
        labelFontName = "System"
        iconHoverEffect = 0
        labelR = 1.0
        labelG = 1.0
        labelB = 1.0
        labelA = 1.0

        if backgroundMode == 1 {
            if !themeManager.availableThemes.isEmpty {
                selectedHTML = themeManager.availableThemes.first ?? ""
            } else {
                backgroundMode = 0
                bgR = 0.2
                bgG = 0.2
                bgB = 0.25
                selectedHTML = ""
            }
        } else {
            backgroundMode = 0
            selectedHTML = ""
        }
    }
}

private struct SettingsGroup<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.accentColor)
                    .frame(width: 18)
                Text(title)
                    .font(.headline)
            }

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.46))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

private struct SettingsSliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let valueText: String

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .frame(width: 138, alignment: .leading)

            Slider(value: $value, in: range)

            Text(valueText)
                .foregroundColor(.secondary)
                .monospacedDigit()
                .frame(width: 56, alignment: .trailing)
        }
    }
}

private struct SettingsStepperRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        Stepper(value: $value, in: range) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value)")
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
        }
    }
}

private struct HoverEffectOptionCard: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.accentColor)
                    }
                }

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.12) : Color(nsColor: .controlBackgroundColor).opacity(0.38))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? Color.accentColor.opacity(0.72) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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
        Button(action: { onPick(r, g, b) }) {
            Circle()
                .fill(Color(red: r, green: g, blue: b))
                .frame(width: 22, height: 22)
                .overlay(
                    Circle().stroke(baseBorderColor, lineWidth: 1).opacity(isSelected ? 0 : 1)
                )
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
        0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    private var baseBorderColor: Color {
        luminance > 0.7 ? Color.black.opacity(0.25) : Color.white.opacity(0.2)
    }

    private var selectionBorderColor: Color {
        luminance > 0.7 ? Color.black.opacity(0.7) : Color.white.opacity(0.9)
    }
}
