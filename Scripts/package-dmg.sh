#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-0.1.0}"
APP_NAME="Clawd"
APP_DIR="$ROOT/build/$APP_NAME.app"
OUTPUT_DIR="$ROOT/output"
STAGING_DIR="$OUTPUT_DIR/dmg-staging"
DMG_PATH="$OUTPUT_DIR/$APP_NAME-$VERSION.dmg"

"$ROOT/Scripts/build.sh"

rm -rf "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$STAGING_DIR"

ditto "$APP_DIR" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"

xattr -cr "$STAGING_DIR"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

shasum -a 256 "$DMG_PATH" > "$DMG_PATH.sha256"

echo "Created $DMG_PATH"
echo "Checksum $DMG_PATH.sha256"
