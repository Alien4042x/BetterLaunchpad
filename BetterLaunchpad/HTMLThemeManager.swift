//
//  HTMLThemeManager.swift
//  BetterLaunchpad
//
//  Created by Radim Veselý on 02.12.2025.
//

import SwiftUI
import Foundation

class HTMLThemeManager: ObservableObject {
    static let shared = HTMLThemeManager()
    
    @Published var availableThemes: [String] = []
    @Published var isInitialized: Bool = false
    
    private init() {
        loadThemes()
    }
    
    func refreshThemes() {
        loadThemes()
    }
    
    private func loadThemes() {
        DispatchQueue.global(qos: .background).async {
            let themes = self.listAvailableHTMLThemes()
            DispatchQueue.main.async {
                self.availableThemes = themes
                self.isInitialized = true
                print("Loaded \(themes.count) HTML themes: \(themes)")
            }
        }
    }
    
    private func listAvailableHTMLThemes() -> [String] {
        var themes: [String] = []
        
        // Check bundle themes
        if let bundleThemesURL = Bundle.main.url(forResource: "HTMLThemes", withExtension: nil, subdirectory: "Resources") {
            if let bundleContents = try? FileManager.default.contentsOfDirectory(at: bundleThemesURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) {
                for url in bundleContents {
                    var isDir: ObjCBool = false
                    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                        let themeName = url.lastPathComponent
                        let htmlPath = url.appendingPathComponent("\(themeName).html")
                        if FileManager.default.fileExists(atPath: htmlPath.path) {
                            themes.append(themeName)
                        }
                    }
                }
            }
        }
        
        // Check custom themes
        let customDir = getCustomThemesDirectory()
        if let customContents = try? FileManager.default.contentsOfDirectory(at: customDir, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) {
            for url in customContents {
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                    let themeName = url.lastPathComponent
                    let htmlPath = url.appendingPathComponent("\(themeName).html")
                    if FileManager.default.fileExists(atPath: htmlPath.path) {
                        themes.append(themeName)
                    }
                }
            }
        }
        
        return themes.sorted()
    }
    
    private func getCustomThemesDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let customThemes = appSupport.appendingPathComponent("BetterLaunchpad/CustomThemes")
        
        if !FileManager.default.fileExists(atPath: customThemes.path) {
            try? FileManager.default.createDirectory(at: customThemes, withIntermediateDirectories: true)
        }
        
        return customThemes
    }
    
    // Public property for external access
    var customThemesDirectory: URL {
        return getCustomThemesDirectory()
    }
}
