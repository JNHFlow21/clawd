#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT/build/Clawd.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
MODULE_CACHE_DIR="$ROOT/build/ModuleCache"
TMP_DIR="$ROOT/build/tmp"
SIGNING_DIR="$(mktemp -d /tmp/clawd-signing.XXXXXX)"
SIGNING_APP="$SIGNING_DIR/Clawd.app"

cleanup() {
  rm -rf "$SIGNING_DIR"
}
trap cleanup EXIT

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR/Animations" "$MODULE_CACHE_DIR" "$TMP_DIR"
rm -rf "$CONTENTS_DIR/_CodeSignature"

export CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_DIR"
export TMPDIR="$TMP_DIR"

swiftc \
  -O \
  -module-cache-path "$MODULE_CACHE_DIR" \
  "$ROOT/Scripts/generate_icon.swift" \
  -framework AppKit \
  -o "$ROOT/build/generate_icon"

"$ROOT/build/generate_icon" "$ROOT/Resources/AppIcon.png" "$ROOT/Resources/AppIcon.icns"

swiftc \
  -O \
  -module-cache-path "$MODULE_CACHE_DIR" \
  "$ROOT"/Sources/Clawd/*.swift \
  -framework AppKit \
  -framework WebKit \
  -framework EventKit \
  -framework ServiceManagement \
  -o "$MACOS_DIR/Clawd"

cp "$ROOT/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$ROOT/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
cp -R "$ROOT/Resources/Animations/." "$RESOURCES_DIR/Animations/"

xattr -cr "$APP_DIR"
rm -rf "$SIGNING_APP"
ditto --noextattr --norsrc "$APP_DIR" "$SIGNING_APP"
xattr -cr "$SIGNING_APP"
codesign --force --deep --sign - "$SIGNING_APP" >/dev/null
codesign --verify --deep --strict "$SIGNING_APP" >/dev/null
rm -rf "$APP_DIR"
ditto --noextattr --norsrc "$SIGNING_APP" "$APP_DIR"
find "$APP_DIR" -exec xattr -d com.apple.FinderInfo {} \; 2>/dev/null || true
find "$APP_DIR" -exec xattr -d com.apple.ResourceFork {} \; 2>/dev/null || true
find "$APP_DIR" -exec xattr -d 'com.apple.fileprovider.fpfs#P' {} \; 2>/dev/null || true

echo "Built $APP_DIR"
