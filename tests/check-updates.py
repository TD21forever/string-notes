from pathlib import Path
import re, subprocess, tempfile
root = Path(__file__).resolve().parents[1]
localization = (root/'Sources/Localization.swift').read_text()
keys = set(re.findall(r'^        "((?:[^"\\]|\\.)*)":', localization, re.M))
for source in (root/'Sources').glob('*.swift'):
    for key in re.findall(r'L\("((?:[^"\\]|\\.)*)"', source.read_text()):
        assert key in keys, (source.name, key)
for key, value in re.findall(r'^        "((?:[^"\\]|\\.)*)": "((?:[^"\\]|\\.)*)"', localization, re.M):
    assert re.findall(r'%[@d]', key) == re.findall(r'%[@d]', value), key
print('PASS: all UI translation keys and format placeholders covered')
checks = r'''
import Cocoa
func check(_ value: @autoclosure () -> Bool, _ name: String) { if !value() { fatalError(name) }; print("PASS: " + name) }
check(AppLanguage.resolve(nil, preferred: ["en-US"]) == "en", "system English")
check(AppLanguage.resolve("system", preferred: ["zh-Hant"]) == "zh-Hans", "system Chinese")
check(AppLanguage.resolve("en", preferred: ["zh-CN"]) == "en", "explicit English")
check(AppLanguage.resolve("zh-Hans", preferred: ["en-US"]) == "zh-Hans", "explicit Chinese")
check(AppLanguage.resolve(nil, preferred: []) == "en", "fallback English")
check(AppLanguage.text("便笺", language: "en") == "Notes", "English translation")
check(AppLanguage.text("便笺", language: "zh-Hans") == "便笺", "Chinese translation")
check(ReleaseVersion("0.9.9")! < ReleaseVersion("v0.10.2")!, "numeric ordering")
check(ReleaseVersion("1.0") == ReleaseVersion("1.0.0+build"), "normalized version")
check(ReleaseVersion("1.0.0-beta.2")! < ReleaseVersion("1.0.0-beta.10")!, "numeric prerelease")
check(ReleaseVersion("1.0.0-rc.1")! < ReleaseVersion("1.0.0")!, "stable after prerelease")
for bad in ["", "v", "1", "1.a.0", "1.0.0-", "1.0.0.1", "9999999999999999999999999.0"] { check(ReleaseVersion(bad) == nil, "reject invalid " + bad) }
func release(_ version: String, draft: Bool = false, host: String = "github.com") -> [String: Any] {
    ["tag_name": "v" + version, "html_url": "https://\(host)/TD21forever/string-notes/releases/tag/v\(version)", "draft": draft, "prerelease": true,
     "assets": ["arm64", "x86_64"].map { arch in ["name": "StringNotes-\(version)-\(arch).zip", "browser_download_url": "https://\(host)/TD21forever/string-notes/releases/download/v\(version)/StringNotes-\(version)-\(arch).zip"] }]
}
let data = try JSONSerialization.data(withJSONObject: [release("0.10.2"), release("0.12.0"), release("0.13.0", draft: true), release("9.0.0", host: "example.com")])
let next = try GitHubRelease.newest(in: data, current: "0.11.0")
check(next?.tag_name == "v0.12.0", "select preview and skip draft or foreign URL")
check(next?.downloadURL(architecture: "arm64")?.lastPathComponent == "StringNotes-0.12.0-arm64.zip", "Apple Silicon asset")
check(next?.downloadURL(architecture: "x86_64")?.lastPathComponent == "StringNotes-0.12.0-x86_64.zip", "Intel asset")
check(next?.downloadURL(architecture: "unknown") == nil, "no incompatible download")
let equal = try GitHubRelease.newest(in: data, current: "0.12.0")
check(equal == nil, "no downgrade or equal update")
let suite = "StringNotes.UpdateTests." + UUID().uuidString
let defaults = UserDefaults(suiteName: suite)!
defer { defaults.removePersistentDomain(forName: suite) }
func finish(_ checker: UpdateChecker) {
    let deadline = Date().addingTimeInterval(3)
    while checker.state == .checking && Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.01)) }
    check(checker.state != .checking, "request completes")
}
var count = 0
let checker = UpdateChecker(defaults: defaults, installedVersion: "0.11.0", fetch: { count += 1; return data })
checker.check(); checker.check(); finish(checker)
check(count == 1 && checker.state == .available(next!), "coalesce checks and show update")
checker.checkAutomatically(); check(count == 1, "daily throttle")
defaults.removeObject(forKey: "lastUpdateCheck"); defaults.set(false, forKey: "automaticUpdateChecks")
checker.checkAutomatically(); check(checker.state == .available(next!) && count == 1, "automatic check opt out")
checker.check(); finish(checker); check(count == 2, "manual check works with opt out")
var fail = true
let retry = UpdateChecker(defaults: defaults, installedVersion: "0.12.0", fetch: { if fail { throw URLError(.notConnectedToInternet) }; return data })
retry.check(); finish(retry); check(retry.state == .failed, "network error is not up to date")
fail = false; retry.check(); finish(retry); check(retry.state == .current, "retry after network error")
let malformed = UpdateChecker(defaults: defaults, fetch: { Data("not json".utf8) })
malformed.check(); finish(malformed); check(malformed.state == .failed, "malformed response is failure")
'''
with tempfile.TemporaryDirectory(prefix='string-notes-update-test-') as folder:
    path = Path(folder)
    (path/'main.swift').write_text(checks)
    subprocess.run(['xcrun','swiftc','-module-cache-path','/tmp/string-notes-module-cache',str(root/'Sources/Localization.swift'),str(root/'Sources/Updates.swift'),str(path/'main.swift'),'-o',str(path/'test')], check=True)
    subprocess.run([str(path/'test')], check=True)
