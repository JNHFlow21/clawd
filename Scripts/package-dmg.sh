#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-0.1.0}"
APP_NAME="Clawd"
APP_DIR="$ROOT/build/$APP_NAME.app"
OUTPUT_DIR="$ROOT/output"
DMG_PATH="$OUTPUT_DIR/$APP_NAME-$VERSION.dmg"
STAGING_DIR="$(mktemp -d /tmp/clawd-dmg-staging.XXXXXX)"
TEMP_DMG="/tmp/$APP_NAME-$VERSION-$$.dmg"

cleanup() {
  rm -rf "$STAGING_DIR" "$TEMP_DMG"
}
trap cleanup EXIT

"$ROOT/Scripts/build.sh"

rm -rf "$DMG_PATH" "$DMG_PATH.sha256" "$TEMP_DMG"
mkdir -p "$STAGING_DIR"

ditto --noextattr --norsrc "$APP_DIR" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"

xattr -cr "$STAGING_DIR"
find "$STAGING_DIR" -exec xattr -d com.apple.FinderInfo {} \; 2>/dev/null || true
find "$STAGING_DIR" -exec xattr -d com.apple.ResourceFork {} \; 2>/dev/null || true
find "$STAGING_DIR" -exec xattr -d 'com.apple.fileprovider.fpfs#P' {} \; 2>/dev/null || true
codesign --verify --deep --strict "$STAGING_DIR/$APP_NAME.app" >/dev/null

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$TEMP_DMG"

mkdir -p "$OUTPUT_DIR"
ditto --noextattr --norsrc "$TEMP_DMG" "$DMG_PATH"
shasum -a 256 "$DMG_PATH" > "$DMG_PATH.sha256"

echo "Created $DMG_PATH"
echo "Checksum $DMG_PATH.sha256"
