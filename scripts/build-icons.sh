#!/bin/zsh
set -eu
cd "$(dirname "$0")/.."
ICON_SOURCE=$(mktemp /tmp/string-notes-icon.XXXXXX.swift)
trap 'rm -f "$ICON_SOURCE"' EXIT
cat Sources/Icons.swift scripts/make-icons.swift > "$ICON_SOURCE"
xcrun swift -module-cache-path /tmp/string-notes-module-cache "$ICON_SOURCE" "$PWD/Assets"
python3 scripts/pack-icons.py
