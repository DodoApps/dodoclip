<p align="center">
  <img src="icon.png" width="128" height="128" alt="DodoClip Icon">
</p>

<h1 align="center">DodoClip</h1>

<p align="center">
  A free, open-source clipboard manager for macOS.
</p>

<p align="center">
  <a href="README.md">🇺🇸 English</a> •
  <a href="README.de.md">🇩🇪 Deutsch</a> •
  <a href="README.tr.md">🇹🇷 Türkçe</a> •
  <a href="README.fr.md">🇫🇷 Français</a> •
  <a href="README.es.md">🇪🇸 Español</a>
</p>

## Description

DodoClip is a lightweight, native clipboard manager built with SwiftUI and SwiftData. It helps you keep track of everything you copy and access your clipboard history instantly.

## Features

- **Clipboard history** - Automatically saves everything you copy with persistence
- **Search** - Quickly find items in your clipboard history
- **Keyboard shortcuts** - Access your clipboard with global hotkeys (⇧⌘V)
- **Pinned items** - Keep important clips always accessible
- **Smart collections** - Auto-organized by type (Links, Images, Colors)
- **Image support** - Copy and manage images alongside text
- **Link previews** - Automatic favicon and og:image fetching
- **Color detection** - Recognizes hex color codes with visual preview
- **Paste stack** - Sequential pasting mode (⇧⌘C)
- **Privacy controls** - Ignore password managers and specific apps
- **Menu bar access** - Quick access from the menu bar

## Requirements

- macOS 14.0 (Sonoma) or later

## Installation

### Homebrew (recommended)

```bash
brew tap bluewave-labs/tap
brew install --cask dodoclip
```

Or install directly without tapping:

```bash
brew install --cask bluewave-labs/tap/dodoclip
```

### Direct download

Download the latest `.dmg` from the [Releases](https://github.com/bluewave-labs/dodoclip/releases) page, open it, and drag DodoClip to your Applications folder.

## Building from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/bluewave-labs/dodoclip.git
   cd DodoClip
   ```

2. Build using Swift Package Manager:
   ```bash
   swift build
   ```

3. Run the app:
   ```bash
   swift run DodoClip
   ```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
