#!/bin/zsh
set -eu
cd "$(dirname "$0")/.."
VERSION="$(cat VERSION)"
ARCH="${STRING_NOTES_ARCH:-arm64}"
APP="${1:-$PWD/build/绳上便笺.app}"
[[ -d "$APP" ]]
codesign --verify --deep --strict "$APP"
[[ "$(lipo -archs "$APP/Contents/MacOS/StringNotes")" == "$ARCH" ]]
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/string-notes-dmg.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
ditto "$APP" "$STAGE/绳上便笺.app"
ln -s /Applications "$STAGE/Applications"
cat > "$STAGE/安装说明 - Read Me.txt" <<'TEXT'
将「绳上便笺.app」拖到 Applications 后打开。
此预览版尚未公证；若 macOS 阻止打开，请在系统设置 → 隐私与安全中查看提示。

Drag 绳上便笺.app to Applications, then open it.
This preview is not notarized. If macOS blocks it, check System Settings → Privacy & Security.
TEXT
mkdir -p dist
hdiutil create -volname "String Notes $VERSION" -srcfolder "$STAGE" -ov -format UDZO "dist/StringNotes-$VERSION-$ARCH.dmg"
hdiutil verify "dist/StringNotes-$VERSION-$ARCH.dmg"
(cd dist && shasum -a 256 "StringNotes-$VERSION-$ARCH.dmg" > "StringNotes-$VERSION-$ARCH.dmg.sha256")
