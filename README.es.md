<p align="center">
  <img src="icon.png" width="128" height="128" alt="DodoClip Icon">
</p>

<h1 align="center">DodoClip</h1>

<p align="center">
  Un gestor de portapapeles gratuito y de código abierto para macOS.
</p>

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

Después, concede permiso a DodoClip en estas listas de privacidad de macOS para que el pegado global funcione:

- `Configuración del Sistema > Privacidad y seguridad > Accesibilidad`
- `Configuración del Sistema > Privacidad y seguridad > Monitorización de entrada` si DodoClip aparece en esa lista en tu sistema

Si DodoClip se abre pero al seleccionar un elemento solo actualiza el portapapeles y no pega en la app anterior, elimina DodoClip de esas mismas listas, añádelo de nuevo y vuelve a abrir la app. En algunas configuraciones de macOS este reinicio de permisos es necesario después de instalar o actualizar la aplicación.

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
