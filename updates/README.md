# Signed application updates

Sparkle 2.10.0 is pinned by SHA-256 in `scripts/prepare-sparkle.sh`. Each architecture uses its own signed appcast at the latest GitHub Release, so Intel and Apple Silicon packages cannot be mixed. The entire feed and ZIP are Ed25519 signed and verified before extraction. No profiling or unattended installation is enabled.

`public-key.txt` is the public key embedded in the app. The corresponding private key is stored in the maintainer’s macOS login Keychain under Sparkle account `local.stringnotes.app`. Never commit or log this private key. Losing it can prevent existing unsigned installations from accepting future updates; keep a secure backup using Sparkle’s documented key-transfer procedure.

GitHub Actions requires the **SPARKLE_PRIVATE_KEY** repository secret. It is only passed to `generate_appcast` through standard input, never command-line arguments or a file. The release workflow refuses to publish if the secret is missing or signing fails. The generated `appcast-arm64.xml` and `appcast-x86_64.xml` must be uploaded with the ZIPs and other release assets.

For local releases, run `python3 scripts/sign-appcasts.py` after producing both ZIPs. Without the environment secret, it signs using the project-specific Keychain account. Verify the resulting feeds against `public-key.txt` before publication. Do not modify an XML feed after it is signed.

Before tagging a release, update VERSION, both READMEs, and release-notes/vVERSION.md. The first release including Sparkle must be installed manually by users on 0.12.0 or earlier. The app’s automatic-check opt-out migrates to Sparkle. Homebrew users can keep using brew upgrade; in-app updates replace the app bundle, not Homebrew’s installation receipt.

A save failure or active input-method composition cancels application termination. Never force-quit the app from the updater delegate. User note storage remains separate from the application bundle.
