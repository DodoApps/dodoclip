<p align="center">
  <img src="icon.png" width="128" height="128" alt="DodoClip Icon">
</p>

<h1 align="center">DodoClip</h1>

<p align="center">
  Ein kostenloser, quelloffener Zwischenablage-Manager für macOS.
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



## Beschreibung

DodoClip ist ein leichtgewichtiger, nativer Zwischenablage-Manager, der mit SwiftUI und SwiftData entwickelt wurde. Er hilft dir, alles zu verfolgen, was du kopierst, und sofort auf deinen Zwischenablage-Verlauf zuzugreifen.

## Funktionen

- **Zwischenablage-Verlauf** - Speichert automatisch alles, was du kopierst, mit Persistenz
- **Suche** - Finde schnell Einträge in deinem Zwischenablage-Verlauf
- **Tastenkürzel** - Greife mit globalen Hotkeys auf deine Zwischenablage zu (⇧⌘V)
- **Angeheftete Einträge** - Behalte wichtige Clips immer griffbereit
- **Intelligente Sammlungen** - Automatisch nach Typ organisiert (Links, Bilder, Farben)
- **Bildunterstützung** - Kopiere und verwalte Bilder zusammen mit Text
- **Link-Vorschau** - Automatisches Abrufen von Favicon und og:image
- **Farberkennung** - Erkennt Hex-Farbcodes mit visueller Vorschau
- **Einfüge-Stapel** - Sequentieller Einfügemodus (⇧⌘C)
- **Datenschutzkontrollen** - Ignoriere Passwort-Manager und bestimmte Apps
- **Menüleistenzugriff** - Schneller Zugriff über die Menüleiste

## Anforderungen

- macOS 14.0 (Sonoma) oder neuer

## Installation

### Homebrew (empfohlen)

```bash
brew tap bluewave-labs/tap
brew install --cask dodoclip
xattr -cr /Applications/DodoClip.app
```

Oder direkt ohne Tap installieren:

```bash
brew install --cask bluewave-labs/tap/dodoclip
xattr -cr /Applications/DodoClip.app
```

### Direkter Download

Lade die neueste `.dmg` von der [Releases](https://github.com/bluewave-labs/dodoclip/releases)-Seite herunter, öffne sie und ziehe DodoClip in deinen Programme-Ordner.

Nach der Installation führe diesen Befehl aus, um die App zu öffnen:

```bash
xattr -cr /Applications/DodoClip.app
```

## Aus dem Quellcode bauen

1. Repository klonen:
   ```bash
   git clone https://github.com/bluewave-labs/dodoclip.git
   cd DodoClip
   ```

2. Mit Swift Package Manager bauen:
   ```bash
   swift build
   ```

3. App ausführen:
   ```bash
   swift run DodoClip
   ```

## Lizenz

Dieses Projekt ist unter der MIT-Lizenz lizenziert - siehe die [LICENSE](LICENSE)-Datei für Details.

## Mitwirken

Beiträge sind willkommen! Reiche gerne einen Pull Request ein.
