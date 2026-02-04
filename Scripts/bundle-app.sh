#!/bin/bash
# Bundle DodoClip as a macOS .app

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the project root directory (parent of Scripts)
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to project root directory
cd "$PROJECT_ROOT"
echo "📁 Working directory: $PROJECT_ROOT"
echo ""

APP_NAME="DodoClip"
BUILD_DIR=".build/release"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# Parse command line arguments
CLEAN_BUILD=false
if [[ "$1" == "--clean" ]] || [[ "$1" == "-c" ]]; then
    CLEAN_BUILD=true
fi

# Clean build cache if requested or always clean for reliability
echo "🧹 Cleaning build cache..."
swift package clean
echo ""

# Build release
echo "🔨 Building release..."
swift build -c release
echo ""

# Verify executable was created
if [ ! -f "$BUILD_DIR/$APP_NAME" ]; then
    echo "❌ Error: Executable not found at $BUILD_DIR/$APP_NAME"
    echo "Build may have failed. Please check the build output above."
    echo "Current directory: $(pwd)"
    ls -la "$BUILD_DIR/" 2>&1 || echo "Build directory does not exist"
    exit 1
fi

echo "✅ Executable verified at: $BUILD_DIR/$APP_NAME"

# Create app bundle structure
echo "📦 Creating app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/"

# Create icns from png
echo "🎨 Creating icon..."
ICONSET_DIR="/tmp/DodoClip.iconset"
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

# Generate iconset
sips -z 16 16     icon.png --out "$ICONSET_DIR/icon_16x16.png"
sips -z 32 32     icon.png --out "$ICONSET_DIR/icon_16x16@2x.png"
sips -z 32 32     icon.png --out "$ICONSET_DIR/icon_32x32.png"
sips -z 64 64     icon.png --out "$ICONSET_DIR/icon_32x32@2x.png"
sips -z 128 128   icon.png --out "$ICONSET_DIR/icon_128x128.png"
sips -z 256 256   icon.png --out "$ICONSET_DIR/icon_128x128@2x.png"
sips -z 256 256   icon.png --out "$ICONSET_DIR/icon_256x256.png"
sips -z 512 512   icon.png --out "$ICONSET_DIR/icon_256x256@2x.png"
sips -z 512 512   icon.png --out "$ICONSET_DIR/icon_512x512.png"
sips -z 1024 1024 icon.png --out "$ICONSET_DIR/icon_512x512@2x.png"

# Convert to icns
iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns"
rm -rf "$ICONSET_DIR"

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>DodoClip</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.dodoclip.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>DodoClip</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.2.2</string>
    <key>CFBundleVersion</key>
    <string>6</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# Copy resources bundle if exists - place it at app root level where Bundle.module expects it
if [ -d "$BUILD_DIR/DodoClip_DodoClip.bundle" ]; then
    echo "📚 Copying resources bundle..."
    cp -r "$BUILD_DIR/DodoClip_DodoClip.bundle" "$APP_DIR/"
fi

# Verify app bundle was created successfully
if [ ! -d "$APP_DIR" ]; then
    echo "❌ Error: App bundle not created at $APP_DIR"
    exit 1
fi

if [ ! -f "$MACOS_DIR/$APP_NAME" ]; then
    echo "❌ Error: Executable not copied to app bundle"
    exit 1
fi

echo ""
echo "✅ Success! App bundle created at: $APP_DIR"
echo ""
echo "📦 To install, run:"
echo "   cp -r \"$APP_DIR\" /Applications/"
echo ""
echo "🚀 Or run directly:"
echo "   open \"$APP_DIR\""
echo ""
