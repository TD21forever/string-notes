<p align="center">
  <img src="Assets/app-icon.png" width="120" alt="String Notes icon">
</p>

<h1 align="center">String Notes · 绳上便笺</h1>

<p align="center"><strong>Hang a thought. Keep it in sight.</strong></p>

<p align="center">
  Native macOS menu bar notes for little tasks, passing ideas, and things you want to remember.
</p>

<p align="center">
  <a href="https://github.com/TD21forever/string-notes/releases/tag/v0.10.0"><img src="https://img.shields.io/badge/version-0.10.0%20preview-e5b85b" alt="0.10.0 preview"></a>
  <img src="https://img.shields.io/badge/macOS-13%2B-555555" alt="macOS 13+ build target">
  <img src="https://img.shields.io/badge/Apple%20Silicon-arm64-555555" alt="Apple Silicon">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-7d9575" alt="MIT License"></a>
</p>

<p align="center"><strong>English</strong> · <a href="README.zh-CN.md">简体中文</a></p>

<p align="center">
  <a href="#install">Install</a> ·
  <a href="#get-started">Get started</a> ·
  <a href="#your-notes-and-backups">Your notes & backups</a> ·
  <a href="https://github.com/TD21forever/string-notes/issues">Report an issue</a>
</p>

Pause your pointer over the menu bar and a string of colorful notes slides into view. Open a note to catch a thought, drag its clip to move it along the string, and archive it when you are done. Tuck the string away when you want to focus.

Built with **Swift, SwiftUI, and AppKit**. No account required. Your notes and images stay on your Mac.

> The current app interface is in Chinese. This English README makes the project easier to discover; it does not indicate an English app localization.

## A place for the little things

| | What String Notes offers |
| --- | --- |
| **Keep it in sight** | Colorful notes on a transparent string. Drag clips to reorder them; empty areas of the overlay let clicks pass through to the app underneath. |
| **Catch a thought** | Open notes from the menu bar or a global shortcut. Changes save automatically, with multiple note windows and individual always-on-top controls. |
| **Make yourself at home** | Native text editing, find, undo and redo, adjustable fonts and sizes, and common Markdown formatting. |
| **Add more than words** | Paste or insert images. Drag their corner handles to resize them; each image remembers its own size. |
| **Put things away** | Search the note library, archive finished notes, and recover deleted notes from the trash. |
| **Set your own rhythm** | Customize global shortcuts, turn off hover-to-reveal, reduce motion, and export a complete backup whenever you need one. |

## Install

The current preview is available for **Apple Silicon Macs (M-series chips)**. The minimum build target is **macOS 13 Ventura**; compatibility has not yet been tested on a device running that minimum version. An Intel download is not available yet.

### Homebrew

```bash
brew install --cask TD21forever/tap/string-notes
```

### Direct download

Download `StringNotes-0.10.0-arm64.zip` from the [v0.10.0 release page](https://github.com/TD21forever/string-notes/releases/tag/v0.10.0), unzip it, and move **绳上便笺.app** to Applications. Open it to get started.

> **Opening the preview for the first time**
>
> This build is ad-hoc signed and has not been signed with a Developer ID or notarized by Apple. macOS may block the first launch. Where your macOS version offers the option, use Finder's right-click → Open or System Settings → Privacy & Security to approve an app you trust. If normal approval is unavailable, wait for a notarized build or build from source.

<details>
<summary>Upgrade or uninstall with Homebrew</summary>

Upgrade:

```bash
brew update
brew upgrade --cask TD21forever/tap/string-notes
```

Uninstall the app:

```bash
brew uninstall --cask string-notes
```

A normal uninstall keeps your local notes. The cask does not define a `zap` action that removes user data.

</details>

## Get started

1. **Reveal the string.** Click the note icon in the menu bar, or pause your pointer over the menu bar.
2. **Hang your first note.** Click **＋** beside the string and start writing. Changes save automatically.
3. **Arrange your thoughts.** Click a note to edit it, drag its clip to change its position, or keep an editor window on top.
4. **Archive what is done.** Archive a note, then find it in the library (**所有便笺**) whenever you want to read it or hang it back on the string.

Right-click the menu bar icon to open the library, settings (**设置**), or quit the app.

<details>
<summary>Keyboard shortcuts</summary>

Global shortcuts can be changed or cleared in settings. They do not require Accessibility permission.

| Action | Default global shortcut |
| --- | --- |
| New note | ⌃⌥⌘N |
| Open the library | ⌃⌥⌘A |
| Open the archive | ⌃⌥⌘L |
| Show / hide the string | ⌃⌥⌘S |

Inside the editor:

| Action | Shortcut |
| --- | --- |
| New line | Return |
| Find | ⌘F |
| Undo / redo | ⌘Z / ⇧⌘Z |
| Save and close | ⌘Return |
| Dismiss find; otherwise save and close | Esc |
| New note | ⌘N |
| Open settings | ⌘, |

</details>

<details>
<summary>Markdown support</summary>

Live formatting supports headings, emphasis, code, quotes, lists, and task text.

Task lists are currently formatted text; their checkboxes cannot be clicked to toggle completion. The editor is not a full CommonMark implementation.

</details>

## Your notes and backups

**Notes are stored locally on your Mac. No account is needed, and there is currently no automatic cloud sync.** In settings, choose the complete backup export (**完整备份 → 导出**) to save text, images, archived notes, drafts, and trash together. Export a backup before moving to a new Mac or trying a new version.

Importing a backup merges new notes. When an ID already exists, the local version is kept. **Import does not overwrite existing notes and cannot roll back edits to them.**

<details>
<summary>Storage location and save protection</summary>

- Notes: `~/Library/Application Support/StringNotes/notes.json`.
- Images are included as RTFD attachments inside the data file, preserving their original data. Preferences use local UserDefaults.
- Writes use atomic replacement. Corrupt files and unknown data versions are protected from being overwritten.
- Closing an editor or quitting the app triggers a final save. If saving fails, the window stays open or quitting is blocked.
- When legacy array data is first migrated, a copy is kept as `notes-before-v3.json`.

</details>

## Preview status and feedback

This is the **0.10.0 preview**. Isolated tests cover storage, backup merging, corrupt-data protection, image persistence and resizing, Markdown, reorder data logic, and multiple editing sessions. UI behavior still needs broader testing across macOS versions, displays, Chinese input methods, and Spaces.

Automatic cloud sync, automatic version history, in-app updates, and a notarized distribution are not available yet.

Found a problem or have an idea? Open an [issue](https://github.com/TD21forever/string-notes/issues). For bugs, include the app version, macOS version, chip type, and steps to reproduce. Hide private note content before sharing screenshots.

## Local development

<details>
<summary>Get the source, build, and test</summary>

Requires macOS and Xcode Command Line Tools.

```bash
git clone https://github.com/TD21forever/string-notes.git
cd string-notes

# Build the app
./build.sh

# Run isolated tests
python3 tests/check-store.py

# Package a release ZIP and generate its SHA256
./scripts/package.sh
```

The app is written to `build/`; release files are written to `dist/`. [VERSION](VERSION) sets the version number.

The default build is `arm64`. Set `STRING_NOTES_ARCH=x86_64` to try an Intel build; the current release does not include unverified Intel artifacts. After changing the icons, run `./scripts/build-icons.sh` to regenerate the icon resources.

GitHub Actions runs the isolated tests and packages the app. Pushing a `v*` tag that matches `VERSION` creates a preview release. Update the version and checksum in the [Homebrew tap](https://github.com/TD21forever/homebrew-tap) after publishing.

</details>

## License and thanks

String Notes is available under the [MIT License](LICENSE), with its own name and custom-drawn icons.

Thanks to [Tendedero](https://github.com/alejandrobujan/tendedero) for the string-and-clips idea. The string, metal clips, and transparent overlay were adapted from Tendedero; some editing behavior was adapted from [Noty](https://github.com/aimen08/noty). See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for attribution and licenses.
