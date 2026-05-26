#!/usr/bin/env bash
set -euo pipefail

# Installiert Airplane Meetings nach ~/Applications damit Spotlight + Launchpad sie finden.

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Airplane Meetings.app"
SOURCE_APP="$PROJECT_DIR/build/$APP_NAME"
TARGET_DIR="$HOME/Applications"
TARGET_APP="$TARGET_DIR/$APP_NAME"

if [[ ! -d "$SOURCE_APP" ]]; then
    echo "Fehler: $SOURCE_APP nicht gefunden. Bitte erst ./build.sh ausführen."
    exit 1
fi

mkdir -p "$TARGET_DIR"

echo "==> Beende laufende Instanz (falls vorhanden)…"
killall AirplaneMeetings 2>/dev/null || true
sleep 1

echo "==> Kopiere App nach ${TARGET_DIR}…"
rm -rf "$TARGET_APP"
cp -R "$SOURCE_APP" "$TARGET_APP"

echo "==> Signiere ad-hoc…"
codesign --force --deep --sign - "$TARGET_APP"

echo "==> Registriere bei Launch Services (für Spotlight)…"
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister \
    -f "$TARGET_APP" || true

echo ""
echo "Fertig. Du kannst jetzt:"
echo "  • Cmd+Space → \"Airplane Meetings\" tippen"
echo "  • Launchpad öffnen und das ✈︎ Icon suchen"
echo "  • Im App-Menü ✈︎ → \"Beim Anmelden starten\" für Autostart aktivieren"
echo ""
echo "App ist installiert unter: $TARGET_APP"
