#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR"

echo "=== [1/3] Derleniyor: Swift Release ==="
swift build -c release

echo "=== [2/3] Paketleniyor: Clippo.app ==="
APP_BUNDLE="build/Clippo.app"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp ".build/release/clippo" "$APP_BUNDLE/Contents/MacOS/clippo"
strip -u -r "$APP_BUNDLE/Contents/MacOS/clippo" 2>/dev/null || true

# Copy Info.plist
cp "Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# Copy AppIcon
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi
if [ -f "Resources/AppIcon.png" ]; then
    cp "Resources/AppIcon.png" "$APP_BUNDLE/Contents/Resources/AppIcon.png"
fi

echo "=== [3/3] İmzalanıyor: Ad-hoc Codesign ==="
codesign --force --deep --sign - "$APP_BUNDLE"

# Sync to root Clippo.app for convenient local testing
rm -rf Clippo.app
cp -R "$APP_BUNDLE" Clippo.app

echo "Tamamlandı: $APP_BUNDLE başarıyla oluşturuldu!"
