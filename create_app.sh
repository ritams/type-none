#!/bin/bash

# Configuration
APP_NAME="TypeNone"
BUILD_PATH="TypeNone/.build/release/TypeNone"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "📦 Packaging ${APP_NAME}..."

# 1. Build release binary
echo "🔨 Building release binary..."
cd TypeNone
swift build -c release -Xswiftc -O
cd ..

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

# 2. Create Bundle Structure
echo "📂 Creating app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# 3. Copy Binary
echo "dg Copying executable..."
cp "${BUILD_PATH}" "${MACOS_DIR}/${APP_NAME}"

# 4. Create Info.plist
echo "📝 Creating Info.plist..."
cat > "${CONTENTS_DIR}/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.ritams.TypeNone</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSMicrophoneUsageDescription</key>
    <string>Type None needs microphone access to listen to your voice for transcription.</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>Type None needs to control System Events to paste text into other applications.</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
</dict>
</plist>
EOF

# 5. Copy Icon
echo "🎨 Copying app icon..."
cp "TypeNone/Resources/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"

# 6. Ad-hoc sign the app
echo "🔏 Ad-hoc signing..."
codesign -s - --deep --force "${APP_BUNDLE}"

# 7. Clean up
echo "✅ ${APP_NAME}.app created successfully!"
echo "To run: open ${APP_NAME}.app"
