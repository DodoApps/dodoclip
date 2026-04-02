<p align="center">
  <img src="icon.png" width="128" height="128" alt="DodoClip Icon">
</p>

<h1 align="center">DodoClip</h1>

<p align="center">
  Ein kostenloser, quelloffener Zwischenablage-Manager für macOS.
</p>

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

Erteile DodoClip danach in diesen macOS-Datenschutzlisten die erforderlichen Berechtigungen, damit globales Einfügen funktioniert:

- `Systemeinstellungen > Datenschutz & Sicherheit > Bedienungshilfen`
- `Systemeinstellungen > Datenschutz & Sicherheit > Eingabekontrolle`, falls DodoClip dort auf deinem System angezeigt wird

Wenn DodoClip zwar startet, aber beim Auswählen eines Eintrags nur die Zwischenablage aktualisiert und nichts in die vorherige App einfügt, entferne DodoClip aus genau diesen Listen, füge die App erneut hinzu und starte sie neu. Auf manchen macOS-Systemen ist diese Aktualisierung nach einer Installation oder einem Update erforderlich.

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
