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
func check(_ value: @autoclosure () -> Bool, _ name: String) { precondition(value(), name); print("PASS: " + name) }
check(AppLanguage.resolve(nil, preferred: ["en-US"]) == "en", "system English")
check(AppLanguage.resolve("system", preferred: ["zh-Hant"]) == "zh-Hans", "system Chinese")
check(AppLanguage.resolve("en", preferred: ["zh-CN"]) == "en", "explicit English")
check(AppLanguage.resolve("zh-Hans", preferred: ["en-US"]) == "zh-Hans", "explicit Chinese")
check(AppLanguage.text("便笺", language: "en") == "Notes", "English translation")
let name = "StringNotes.UpdateTests." + UUID().uuidString
let defaults = UserDefaults(suiteName: name)!
defer { defaults.removePersistentDomain(forName: name) }
UpdatePreferences.migrate(defaults)
check(defaults.bool(forKey: "SUEnableAutomaticChecks"), "first launch enables checks")
defaults.removeObject(forKey: "SUEnableAutomaticChecks")
defaults.set(false, forKey: "automaticUpdateChecks")
UpdatePreferences.migrate(defaults)
check(!defaults.bool(forKey: "SUEnableAutomaticChecks"), "preserve existing opt out")
defaults.set(true, forKey: "SUEnableAutomaticChecks")
UpdatePreferences.migrate(defaults)
check(defaults.bool(forKey: "SUEnableAutomaticChecks"), "do not overwrite newer Sparkle setting")
'''
with tempfile.TemporaryDirectory(prefix='string-notes-update-test-') as folder:
    path = Path(folder)
    (path/'main.swift').write_text(checks)
    framework = root/'.build/sparkle'
    subprocess.run([str(root/'scripts/prepare-sparkle.sh')],check=True)
    subprocess.run(['xcrun','swiftc','-module-cache-path','/tmp/string-notes-module-cache',str(root/'Sources/Localization.swift'),str(root/'Sources/Updates.swift'),str(path/'main.swift'),'-F',str(framework),'-framework','Sparkle','-Xlinker','-rpath','-Xlinker',str(framework),'-o',str(path/'test')], check=True)
    subprocess.run([str(path/'test')], check=True)
