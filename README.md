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
  <a href="README.es.md">🇪🇸 Español</a> •
  <a href="README.zh-Hans.md">🇨🇳 简体中文</a> •
  <a href="README.zh-Hant.md">🇨🇳 繁體中文</a>
</p>



https://github.com/user-attachments/assets/f281b654-a0a2-4883-b09c-21aa2cd3efb4



## Description

DodoClip is a lightweight, native clipboard manager built with SwiftUI and SwiftData. It helps you keep track of everything you copy and access your clipboard history instantly.

## Features

- **Clipboard history** - Automatically saves everything you copy with persistence
- **Search** - Quickly find items in your clipboard history
- **OCR support** - Find any strings in your images you copied
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
xattr -cr /Applications/DodoClip.app
```

Or install directly without tapping:

```bash
brew install --cask bluewave-labs/tap/dodoclip
xattr -cr /Applications/DodoClip.app
```

### Direct download

Download the latest `.dmg` from the [Releases](https://github.com/bluewave-labs/dodoclip/releases) page, open it, and drag DodoClip to your Applications folder.

After installing, run this command to allow the app to open:

```bash
xattr -cr /Applications/DodoClip.app
```

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

## FAQ

### "DodoClip is damaged and can't be opened"

This message appears because the app isn't signed with an Apple Developer certificate. It's not actually damaged. To fix this, open Terminal and run:

```bash
xattr -cr /Applications/DodoClip.app
```

Then open DodoClip again.

### I double-clicked the app but nothing happened

DodoClip is a **menu bar app** - it runs in the background and appears as an icon in your menu bar (top-right corner of your screen). Press **⇧⌘V** (Shift+Command+V) to open the clipboard panel.

### How do I quit DodoClip?

Click the DodoClip icon in the menu bar and select "Quit", or press **⌘Q** when the panel is open.

### Does DodoClip store my clipboard data securely?

Your clipboard history is stored locally on your Mac using SwiftData. Nothing is sent to external servers. You can also enable privacy controls to ignore password managers and specific apps.

### Can I search for text inside images?

Yes! DodoClip has OCR (Optical Character Recognition) support. When you copy an image, it automatically extracts any text from it. You can then search for that text in the clipboard panel.

### What's the Paste Stack feature?

Paste Stack (⇧⌘C) lets you queue multiple items and paste them one by one in sequence. Great for filling out forms or moving multiple pieces of data.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

Part of the Dodo app family ([DodoPulse](https://github.com/bluewave-labs/dodopulse), [DodoTidy](https://github.com/bluewave-labs/dodotidy), [DodoClip](https://github.com/bluewave-labs/dodoclip), [DodoNest](https://github.com/bluewave-labs/dodonest))
