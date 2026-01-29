#!/bin/bash
# Bundle DodoClip as a macOS .app

set -e

APP_NAME="DodoClip"
BUILD_DIR=".build/release"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# Build release
echo "Building release..."
swift build -c release

# Create app bundle structure
echo "Creating app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/"

# Create icns from png
echo "Creating icon..."
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
    <string>1.2.1</string>
    <key>CFBundleVersion</key>
    <string>5</string>
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

# Copy resources bundle if exists
if [ -d "$BUILD_DIR/DodoClip_DodoClip.bundle" ]; then
    cp -r "$BUILD_DIR/DodoClip_DodoClip.bundle" "$RESOURCES_DIR/"
fi

echo "Done! App bundle created at: $APP_DIR"
echo "To install, copy to /Applications:"
echo "  cp -r \"$APP_DIR\" /Applications/"
