<p align="center">
  <img src="icon.png" width="128" height="128" alt="DodoClip Icon">
</p>

<h1 align="center">DodoClip</h1>

<p align="center">
  Un gestionnaire de presse-papiers gratuit et open-source pour macOS.
</p>

## Description

DodoClip est un gestionnaire de presse-papiers natif et léger, construit avec SwiftUI et SwiftData. Il vous aide à garder une trace de tout ce que vous copiez et à accéder instantanément à votre historique de presse-papiers.

## Fonctionnalités

- **Historique du presse-papiers** - Sauvegarde automatiquement tout ce que vous copiez avec persistance
- **Recherche** - Trouvez rapidement des éléments dans votre historique de presse-papiers
- **Raccourcis clavier** - Accédez à votre presse-papiers avec des raccourcis globaux (⇧⌘V)
- **Éléments épinglés** - Gardez les clips importants toujours accessibles
- **Collections intelligentes** - Organisation automatique par type (Liens, Images, Couleurs)
- **Support des images** - Copiez et gérez des images avec du texte
- **Aperçu des liens** - Récupération automatique des favicons et og:image
- **Détection des couleurs** - Reconnaît les codes couleur hexadécimaux avec aperçu visuel
- **Pile de collage** - Mode de collage séquentiel (⇧⌘C)
- **Contrôles de confidentialité** - Ignorez les gestionnaires de mots de passe et certaines applications
- **Accès barre de menus** - Accès rapide depuis la barre de menus

## Configuration requise

- macOS 14.0 (Sonoma) ou ultérieur

## Installation

### Homebrew (recommandé)

```bash
brew tap bluewave-labs/tap
brew install --cask dodoclip
xattr -cr /Applications/DodoClip.app
```

Ou installer directement sans tap :

```bash
brew install --cask bluewave-labs/tap/dodoclip
xattr -cr /Applications/DodoClip.app
```

### Téléchargement direct

Téléchargez le dernier `.dmg` depuis la page [Releases](https://github.com/bluewave-labs/dodoclip/releases), ouvrez-le et glissez DodoClip dans votre dossier Applications.

Après l'installation, exécutez cette commande pour autoriser l'ouverture de l'app :

```bash
xattr -cr /Applications/DodoClip.app
```

Accordez ensuite à DodoClip les autorisations nécessaires dans ces listes macOS pour que le collage global fonctionne :

- `Réglages Système > Confidentialité et sécurité > Accessibilité`
- `Réglages Système > Confidentialité et sécurité > Surveillance de l'entrée` si DodoClip apparaît dans cette liste sur votre système

Si DodoClip s'ouvre mais que la sélection d'un élément met seulement à jour le presse-papiers sans coller dans l'application précédente, supprimez DodoClip de ces mêmes listes, ajoutez-le de nouveau, puis relancez l'app. Sur certaines configurations macOS, cette réinitialisation est nécessaire après une installation ou une mise à jour.

## Compilation depuis les sources

1. Clonez le dépôt :
   ```bash
   git clone https://github.com/bluewave-labs/dodoclip.git
   cd DodoClip
   ```

2. Compilez avec Swift Package Manager :
   ```bash
   swift build
   ```

3. Lancez l'application :
   ```bash
   swift run DodoClip
   ```

## Licence

Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour plus de détails.

## Contribution

Les contributions sont les bienvenues ! N'hésitez pas à soumettre une Pull Request.
