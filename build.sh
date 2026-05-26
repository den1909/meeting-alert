#!/usr/bin/env bash
set -euo pipefail

# Airplane Meetings — Build-Skript
# Erzeugt eine .app aus dem Swift Package und signiert sie ad-hoc.

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="AirplaneMeetings"
DISPLAY_NAME="Airplane Meetings"
BUNDLE_ID="com.dennisbacher.airplanemeetings"
BUILD_DIR="$PROJECT_DIR/.build"
APP_DIR="$PROJECT_DIR/build/${DISPLAY_NAME}.app"

cd "$PROJECT_DIR"

echo "==> Baue Swift Package (release)…"
UNIVERSAL_EXEC="$PROJECT_DIR/.build/apple/Products/Release/$APP_NAME"
if swift build -c release --arch arm64 --arch x86_64 2>/dev/null; then
    EXECUTABLE="$UNIVERSAL_EXEC"
else
    swift build -c release
    BIN_PATH="$(swift build -c release --show-bin-path)"
    EXECUTABLE="$BIN_PATH/$APP_NAME"
fi

if [[ ! -f "$EXECUTABLE" ]]; then
    echo "Fehler: Executable nicht gefunden unter $EXECUTABLE"
    exit 1
fi

echo "==> Erzeuge App-Bundle-Struktur…"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$EXECUTABLE" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$PROJECT_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"

# Resource-Bundle des Swift Packages kopieren (für eingebundene Assets, falls vorhanden)
BUNDLE_RES="$(dirname "$EXECUTABLE")/AirplaneMeetings_AirplaneMeetings.bundle"
if [[ -d "$BUNDLE_RES" ]]; then
    cp -R "$BUNDLE_RES" "$APP_DIR/Contents/Resources/"
fi

echo "==> Signiere ad-hoc…"
codesign --force --deep --sign - "$APP_DIR"

echo ""
echo "Fertig: $APP_DIR"
echo ""
echo "Starten mit:"
echo "  open \"$APP_DIR\""
echo ""
echo "Beim ersten Start fragt macOS nach Kalender-Berechtigung."
