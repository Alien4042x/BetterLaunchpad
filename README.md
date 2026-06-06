# BetterLaunchpad

BetterLaunchpad is a macOS application launcher with a paginated app grid, search, favorites, configurable layout, and custom backgrounds.

It was built as a replacement for the system Applications-style view, with more control over spacing, appearance, and navigation.

<img width="3552" height="1406" alt="BetterLaunchpad" src="https://github.com/user-attachments/assets/7b6a02d0-54d4-4876-ac47-f5626b1e62c5" />

## Features

- Custom grid layout with configurable rows, columns, and icon size
- Fast app search with live filtering
- Favorites section
- Keyboard, mouse wheel, and gesture navigation
- Glass, solid color, and HTML background modes
- Built-in HTML themes and support for custom themes
- Configurable label font, color, and icon hover effects
- Localized interface for 15 languages

## Requirements

- macOS 26.0.1 or newer
- Xcode 26.0.1 or newer for building from source
- Swift 6.2 or newer

## Installation

Download the latest release from [Releases](https://github.com/Alien4042x/BetterLaunchpad/releases), then move `BetterLaunchpad.app` to your Applications folder.

To build from source:

```bash
git clone https://github.com/Alien4042x/BetterLaunchpad.git
cd BetterLaunchpad
open BetterLaunchpad.xcodeproj
```

In Xcode, select the BetterLaunchpad scheme and run with `Cmd + R`.

## Usage

- Launch BetterLaunchpad to show the app grid
- Type to search applications
- Click an app icon to launch it
- Use arrow keys, mouse wheel, or swipe gestures to change pages
- Press `Esc` to quit
- Press `Cmd + ,` to open Settings
- Press `Cmd + F` to focus search

## Customization

Settings include:

- Grid rows and columns
- Icon size
- Background type and opacity
- Built-in or custom HTML themes
- Label font, size, weight, color, and opacity
- Icon hover effect

Changes apply immediately.

## Custom HTML Themes

Custom themes live here:

```text
~/Library/Application Support/BetterLaunchpad/CustomThemes/
```

Each theme needs its own folder. The folder and file names must match:

```text
CustomThemes/
└── mytheme/
    ├── mytheme.html
    ├── mytheme.css
    └── mytheme.js
```

Only the HTML file is required. CSS and JavaScript are optional.

Recommended theme rules:

- Use relative paths for CSS and JavaScript
- Set `overflow: hidden` to avoid scrollbars
- Use `requestAnimationFrame()` for animation
- Handle window resize if you use canvas

After adding a theme, open Settings, choose HTML background mode, and refresh the theme list.

## Localization

Supports 15 languages covering 60%+ of the global population:

🇺🇸 English • 🇪🇸 Spanish • 🇫🇷 French • 🇩🇪 German • 🇷🇺 Russian • 🇺🇦 Ukrainian • 🇨🇳 Chinese • 🇯🇵 Japanese • 🇰🇷 Korean • 🇮🇹 Italian • 🇵🇹 Portuguese • 🇳🇱 Dutch • 🇵🇱 Polish • 🇨🇿 Czech • 🇸🇰 Slovak

| Language | Code | Status |
| --- | --- | --- |
| English | en | ✅ Complete |
| Czech | cs | ✅ Complete |
| Slovak | sk | ✅ Complete |
| German | de | ✅ Complete |
| French | fr | ✅ Complete |
| Spanish | es | ✅ Complete |
| Italian | it | ✅ Complete |
| Dutch | nl | ✅ Complete |
| Portuguese | pt | ✅ Complete |
| Polish | pl | ✅ Complete |
| Russian | ru | ✅ Complete |
| Ukrainian | uk | ✅ Complete |
| Japanese | ja | ✅ Complete |
| Korean | ko | ✅ Complete |
| Chinese (Simplified) | zh-Hans | ✅ Complete |

To add a language, create a new `[language-code].lproj/Localizable.strings` file, translate the keys from `en.lproj/Localizable.strings`, and add the localization in Xcode.

## Project Structure

```text
BetterLaunchpad/
├── BetterLaunchpadApp.swift
├── ContentView.swift
├── Settings.swift
├── AboutView.swift
├── GlassBackground.swift
├── GlassSearchBar.swift
├── HTMLThemeManager.swift
├── FavoritesManager.swift
├── FavoritesModal.swift
├── Resources/
│   └── HTMLThemes/
└── *.lproj/
```

## License

BetterLaunchpad is licensed under the MIT License. See [LICENSE](LICENSE).
