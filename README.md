# BetterLaunchpad

<div align="center">

![BetterLaunchpad Logo](https://img.shields.io/badge/BetterLaunchpad-v1.0-blue?style=for-the-badge&logo=apple)

**A modern, customizable application launcher for macOS**

[![macOS](https://img.shields.io/badge/macOS-11.0+-blue?style=flat-square&logo=apple)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange?style=flat-square&logo=swift)](https://swift.org/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-4.0+-green?style=flat-square&logo=swift)](https://developer.apple.com/xcode/swiftui/)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)](LICENSE)

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [Localization](#-localization) • [Contributing](#-contributing)

</div>

## 🚀 Features

### ✨ **Core Features**

- **🎯 Smart Grid Layout** - Customizable rows (2-5) and columns (3-8)
- **🔍 Intelligent Search** - Fast application search with real-time filtering
- **🎨 Glass Effects** - Beautiful transparency and blur effects with multiple materials
- **🌈 Custom Theming** - Personalize colors, fonts, and transparency
- **⚡ Lightning Fast** - Instant launch and smooth animations
- **🎮 Intuitive Navigation** - Arrow keys, mouse wheel, and gesture support

### 🎨 **Customization Options**

- **Background Modes**: Glass blur effects or solid colors
- **Blur Materials**: HUD Window, Sheet, Popover, Menu, Sidebar, and more
- **Color Palette**: Pre-defined color swatches + custom RGB controls
- **Typography**: System fonts + custom font families with weight control
- **Layout**: Flexible grid with adjustable icon sizes (40-128pt)

### 🌍 **Multi-Language Support**

Supports **14 languages** covering **60%+ of global population**:

🇺🇸 English • 🇪🇸 Spanish • 🇫🇷 French • 🇩🇪 German • 🇷🇺 Russian • 🇺🇦 Ukrainian • 🇨🇳 Chinese • 🇯🇵 Japanese • 🇰🇷 Korean • 🇮🇹 Italian • 🇵🇹 Portuguese • 🇳🇱 Dutch • 🇵🇱 Polish • 🇨🇿 Czech • 🇸🇰 Slovak

> ⚠️ Translations were generated with the help of AI.  
> They may not be 100% perfect – contributions are welcome!

## 📸 Screenshots

### Glass Effect Mode

Beautiful transparency with customizable blur materials and color tinting.

### Solid Color Mode

Clean, solid backgrounds with full opacity control and vibrant colors.

### Settings Panel

Comprehensive customization options with live preview and instant application.

## 🛠 Installation

### Requirements

- **macOS 15.06+** (Sequoia)
- **Xcode 26.0.1+** (for building from source)
- **Swift 6.2+**

### Build from Source

1. **Clone the repository**

   ```bash
   git clone https://github.com/Alien4042x/BetterLaunchpad.git
   cd BetterLaunchpad
   ```

2. **Open in Xcode**

   ```bash
   open BetterLaunchpad.xcodeproj
   ```

3. **Build and Run**
   - Select your target device/simulator
   - Press `Cmd + R` to build and run
   - Or use `Product > Run` from the menu

### Download Release

- Download the latest release from [Releases](https://github.com/Alien4042x/BetterLaunchpad/releases)
- Drag `BetterLaunchpad.app` to your Applications folder
- Launch and enjoy!

## 🎯 Usage

### Basic Usage

1. **Launch BetterLaunchpad** - The app fills your screen with a beautiful grid
2. **Search Applications** - Type to filter apps instantly
3. **Navigate** - Use arrow keys, mouse wheel, or swipe gestures
4. **Launch Apps** - Click any app icon to launch
5. **Quit** - Press `Esc` to exit

### Keyboard Shortcuts

- `Esc` - Quit application
- `Cmd + ,` - Open Settings
- `Cmd + F` - Focus search bar
- `Arrow Keys` - Navigate between pages

### Customization

1. **Open Settings** - `Cmd + ,` or menu bar
2. **Choose Layout** - Adjust rows, columns, and icon size
3. **Select Background** - Enable blur for glass effects or use solid colors
4. **Pick Colors** - Use color swatches or custom RGB sliders
5. **Customize Fonts** - Choose font family, size, and weight
6. **Live Preview** - See changes instantly

## 🌍 Localization

BetterLaunchpad automatically detects your system language and displays the interface accordingly.

### Supported Languages

| Language             | Code    | Speakers | Status      |
| -------------------- | ------- | -------- | ----------- |
| English              | en      | 1.5B     | ✅ Complete |
| Spanish              | es      | 500M     | ✅ Complete |
| Chinese (Simplified) | zh-Hans | 918M     | ✅ Complete |
| French               | fr      | 280M     | ✅ Complete |
| Russian              | ru      | 260M     | ✅ Complete |
| Portuguese           | pt      | 260M     | ✅ Complete |
| Japanese             | ja      | 125M     | ✅ Complete |
| Korean               | ko      | 77M      | ✅ Complete |
| German               | de      | 100M     | ✅ Complete |
| Italian              | it      | 65M      | ✅ Complete |
| Polish               | pl      | 45M      | ✅ Complete |
| Dutch                | nl      | 24M      | ✅ Complete |
| Czech                | cs      | 10M      | ✅ Complete |
| Slovak               | sk      | 5M       | ✅ Complete |
| Ukrainian            | uk      | 30M      | ✅ Complete |

### Adding New Languages

1. Create `[language-code].lproj/Localizable.strings`
2. Translate all keys from `en.lproj/Localizable.strings`
3. Add the language to Xcode project localizations
4. Test with system language change

## 🏗 Architecture

### Project Structure

```
BetterLaunchpad/
├── BetterLaunchpadApp.swift    # Main app entry point
├── ContentView.swift           # Main UI and app grid
├── Settings.swift              # Settings panel
├── AboutView.swift             # About dialog
├── GlassBackground.swift       # Glass effect implementation
├── GlassSearchBar.swift        # Search functionality
└── Localizations/
    ├── en.lproj/              # English
    ├── es.lproj/              # Spanish
    ├── fr.lproj/              # French
    └── ...                    # Other languages
```

### Key Components

- **AppModel** - Application discovery and management
- **GlassBackground** - NSVisualEffectView wrapper for blur effects
- **AppPagerView** - Paginated grid layout with smooth transitions
- **ColorSwatch** - Reusable color picker component

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Add tests if applicable
5. Commit: `git commit -m 'Add amazing feature'`
6. Push: `git push origin feature/amazing-feature`
7. Open a Pull Request

### Areas for Contribution

- 🌍 **Translations** - Add support for more languages
- 🎨 **Themes** - Create new visual themes and effects
- 🚀 **Performance** - Optimize app launch and search speed
- 🐛 **Bug Fixes** - Report and fix issues
- 📚 **Documentation** - Improve docs and examples

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Apple** - For the amazing SwiftUI framework and macOS platform
- **Community** - For feedback, bug reports, and feature requests
- **Translators** - For making BetterLaunchpad accessible worldwide

## 📞 Support

- 🐛 **Bug Reports** - [Open an issue](https://github.com/Alien4042x/BetterLaunchpad/issues)
---

<div align="center">

**Made with ❤️ for the macOS community**

[⭐ Star this repo](https://github.com/Alien4042x/BetterLaunchpad) • [🐛 Report Bug](https://github.com/Alien4042x/BetterLaunchpad/issues)

<img width="3508" height="1383" alt="betterlaunchpad_picture" src="https://github.com/user-attachments/assets/d2c3a883-1562-44e1-86a6-d13b8b86a242" />

</div>
