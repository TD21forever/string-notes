#!/bin/zsh
set -eu
cd "$(dirname "$0")"
VERSION="$(cat VERSION)"
./scripts/prepare-sparkle.sh
SPARKLE="$PWD/.build/sparkle"
UPDATE_KEY="$(cat updates/public-key.txt)"
ARCH="${STRING_NOTES_ARCH:-arm64}"
case "$ARCH" in arm64|x86_64) ;; *) print -u2 "Unsupported architecture: $ARCH"; exit 1 ;; esac
MIN_MACOS="13.0"
APP="$PWD/build/绳上便笺.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks"
ditto "$SPARKLE/Sparkle.framework" "$APP/Contents/Frameworks/Sparkle.framework"
xcrun swiftc -O -target "$ARCH-apple-macosx$MIN_MACOS" -module-cache-path "${TMPDIR:-/tmp}/string-notes-module-cache" Sources/*.swift -o "$APP/Contents/MacOS/StringNotes" -framework Cocoa -framework SwiftUI -framework Carbon -F "$SPARKLE" -framework Sparkle -Xlinker -rpath -Xlinker @executable_path/../Frameworks
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>StringNotes</string>
<key>CFBundleIdentifier</key><string>local.stringnotes.app</string>
<key>CFBundleDevelopmentRegion</key><string>en</string>
<key>CFBundleLocalizations</key><array><string>en</string><string>zh-Hans</string></array>
<key>CFBundleName</key><string>绳上便笺</string>
<key>CFBundleVersion</key><string>$VERSION</string>
<key>CFBundleShortVersionString</key><string>$VERSION</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>SUFeedURL</key><string>https://github.com/TD21forever/string-notes/releases/latest/download/appcast-$ARCH.xml</string>
<key>SUPublicEDKey</key><string>$UPDATE_KEY</string>
<key>SUEnableAutomaticChecks</key><true/>
<key>SUAutomaticallyUpdate</key><false/>
<key>SUAllowsAutomaticUpdates</key><false/>
<key>SUVerifyUpdateBeforeExtraction</key><true/>
<key>SURequireSignedFeed</key><true/>
<key>SUEnableSystemProfiling</key><false/>
<key>SUScheduledCheckInterval</key><integer>86400</integer>
<key>LSUIElement</key><true/>
<key>LSMinimumSystemVersion</key><string>$MIN_MACOS</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
cp Assets/AppIcon.icns THIRD_PARTY_NOTICES.md LICENSE "$APP/Contents/Resources/"
codesign --force --sign - "$APP"
codesign --verify --deep --strict "$APP"
printf '%s\n' "$APP"
