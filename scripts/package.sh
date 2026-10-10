#!/bin/zsh
set -eu
cd "$(dirname "$0")/.."
./build.sh
VERSION="$(cat VERSION)"
ARCH="${STRING_NOTES_ARCH:-arm64}"
mkdir -p dist
ditto -c -k --sequesterRsrc --keepParent "build/绳上便笺.app" "dist/StringNotes-$VERSION-$ARCH.zip"
cd dist
shasum -a 256 "StringNotes-$VERSION-$ARCH.zip" > "StringNotes-$VERSION-$ARCH.zip.sha256"
cat "StringNotes-$VERSION-$ARCH.zip.sha256"
