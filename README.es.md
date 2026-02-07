<p align="center">
  <img src="icon.png" width="128" height="128" alt="DodoClip Icon">
</p>

<h1 align="center">DodoClip</h1>

<p align="center">
  Un gestor de portapapeles gratuito y de código abierto para macOS.
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



## Descripción

DodoClip es un gestor de portapapeles nativo y ligero, construido con SwiftUI y SwiftData. Te ayuda a mantener un registro de todo lo que copias y acceder al historial de tu portapapeles instantáneamente.

## Características

- **Historial del portapapeles** - Guarda automáticamente todo lo que copias con persistencia
- **Búsqueda** - Encuentra rápidamente elementos en el historial de tu portapapeles
- **Atajos de teclado** - Accede a tu portapapeles con atajos globales (⇧⌘V)
- **Elementos fijados** - Mantén los clips importantes siempre accesibles
- **Colecciones inteligentes** - Organización automática por tipo (Enlaces, Imágenes, Colores)
- **Soporte de imágenes** - Copia y gestiona imágenes junto con texto
- **Vista previa de enlaces** - Obtención automática de favicon y og:image
- **Detección de colores** - Reconoce códigos de color hexadecimales con vista previa visual
- **Pila de pegado** - Modo de pegado secuencial (⇧⌘C)
- **Controles de privacidad** - Ignora gestores de contraseñas y aplicaciones específicas
- **Acceso desde la barra de menús** - Acceso rápido desde la barra de menús

## Requisitos

- macOS 14.0 (Sonoma) o posterior

## Instalación

### Homebrew (recomendado)

```bash
brew tap bluewave-labs/tap
brew install --cask dodoclip
xattr -cr /Applications/DodoClip.app
```

O instalar directamente sin tap:

```bash
brew install --cask bluewave-labs/tap/dodoclip
xattr -cr /Applications/DodoClip.app
```

### Descarga directa

Descarga el último `.dmg` desde la página de [Releases](https://github.com/bluewave-labs/dodoclip/releases), ábrelo y arrastra DodoClip a tu carpeta de Aplicaciones.

Después de instalar, ejecuta este comando para permitir que la app se abra:

```bash
xattr -cr /Applications/DodoClip.app
```

## Compilar desde el código fuente

1. Clona el repositorio:
   ```bash
   git clone https://github.com/bluewave-labs/dodoclip.git
   cd DodoClip
   ```

2. Compila usando Swift Package Manager:
   ```bash
   swift build
   ```

3. Ejecuta la aplicación:
   ```bash
   swift run DodoClip
   ```

## Licencia

Este proyecto está licenciado bajo la Licencia MIT - consulta el archivo [LICENSE](LICENSE) para más detalles.

## Contribuir

¡Las contribuciones son bienvenidas! No dudes en enviar un Pull Request.
