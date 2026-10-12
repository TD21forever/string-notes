#!/bin/zsh
set -eu
cd "$(dirname "$0")/.."
VERSION=2.10.0
SHA=c2bf58aa8387266ac179357b1415d6f2635f044da8be41042af32425dae6da0c
ROOT="$PWD/.build/sparkle"
if [[ -f "$ROOT/.verified-$VERSION" && -d "$ROOT/Sparkle.framework" ]]; then exit 0; fi
mkdir -p "$ROOT"
ARCHIVE="$PWD/.build/Sparkle-$VERSION.tar.xz"
if [[ ! -f "$ARCHIVE" ]]; then
  curl --fail --location --retry 3 "https://github.com/sparkle-project/Sparkle/releases/download/$VERSION/Sparkle-$VERSION.tar.xz" -o "$ARCHIVE.part"
  mv "$ARCHIVE.part" "$ARCHIVE"
fi
print "$SHA  $ARCHIVE" | shasum -a 256 -c -
tar -xJf "$ARCHIVE" -C "$ROOT"
codesign --verify --deep --strict "$ROOT/Sparkle.framework"
touch "$ROOT/.verified-$VERSION"
