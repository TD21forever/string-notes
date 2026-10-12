"""Exercise persisted bindings through the same nested settings rows as the app."""
from pathlib import Path
import subprocess, tempfile
root = Path(__file__).resolve().parents[1]
source = (root / 'Sources/Settings.swift').read_text()
rows = source[source.index('struct SettingsGroup'):source.index('struct SettingsView')]
checks = r'''
import Cocoa
import SwiftUI
import Combine
func L(_ text: String) -> String { text }
func check(_ value: @autoclosure () -> Bool, _ name: String) {
    precondition(value(), name); print("PASS: " + name)
}
let suite = "StringNotes.SettingsTests." + UUID().uuidString
let defaults = UserDefaults(suiteName: suite)!
defer { defaults.removePersistentDomain(forName: suite) }
final class Probe {
    var toggle: Binding<Bool>?
    var selection: Binding<String>?
    var renderedToggle = false
    var renderedSelection = ""
}
struct ToggleProbe: View {
    @Binding var value: Bool
    let probe: Probe
    var body: some View {
        probe.toggle = $value
        probe.renderedToggle = value
        return Toggle("Auto hide", isOn: $value).toggleStyle(.switch)
    }
}
struct PickerProbe: View {
    @Binding var value: String
    let probe: Probe
    var body: some View {
        probe.selection = $value
        probe.renderedSelection = value
        return Picker("Display", selection: $value) {
            Text("Mouse").tag("mouse"); Text("Main").tag("main")
        }
    }
}
struct Fixture: View {
    @SettingStorage("ropeAutoHide", store: defaults) var autoHide = true
    @SettingStorage("ropeDisplay", store: defaults) var display = "mouse"
    let probe: Probe
    var body: some View {
        SettingsGroup(title: "Settings") {
            SettingRow(title: "Auto hide") { ToggleProbe(value: $autoHide, probe: probe) }
            SettingRow(title: "Display") { PickerProbe(value: $display, probe: probe) }
        }.frame(width: 400, height: 160)
    }
}
let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let probe = Probe()
let host = NSHostingView(rootView: Fixture(probe: probe))
let window = NSWindow(contentRect: NSRect(x: -2000, y: -2000, width: 400, height: 160), styleMask: [.titled], backing: .buffered, defer: false)
window.contentView = host
func refresh() {
    host.layoutSubtreeIfNeeded()
    RunLoop.main.run(until: Date().addingTimeInterval(0.15))
    host.layoutSubtreeIfNeeded()
}
refresh()
check(probe.renderedToggle && probe.renderedSelection == "mouse", "initial settings rendered through nested rows")
probe.toggle!.wrappedValue = false
probe.selection!.wrappedValue = "main"
check(!probe.toggle!.wrappedValue && probe.selection!.wrappedValue == "main", "bindings immediately report the new values")
refresh()
check(!probe.renderedToggle && probe.renderedSelection == "main", "visible row state updates without reopening settings")
check(!defaults.bool(forKey: "ropeAutoHide") && defaults.string(forKey: "ropeDisplay") == "main", "rendered and persisted settings agree")
probe.toggle!.wrappedValue = true
probe.selection!.wrappedValue = "mouse"
refresh()
check(probe.renderedToggle && probe.renderedSelection == "mouse", "repeated changes do not leave the previous selection")
defaults.set(false, forKey: "ropeAutoHide")
defaults.set("main", forKey: "ropeDisplay")
refresh()
check(!probe.renderedToggle && probe.renderedSelection == "main", "external preferences synchronize into visible rows")
defaults.removeObject(forKey: "ropeAutoHide")
defaults.removeObject(forKey: "ropeDisplay")
refresh()
check(probe.renderedToggle && probe.renderedSelection == "mouse", "reset preferences restores displayed defaults")
for (key, initial, next) in [("noteFontSize", 17.0, 24.0)] {
    let state = SettingValue(key: key, fallback: initial, defaults: defaults)
    state.set(next)
    check(SettingValue(key: key, fallback: initial, defaults: defaults).value == next, "numeric selection survives reopening")
}
let color = SettingValue(key: "defaultColor", fallback: 0, defaults: defaults)
color.set(3)
check(SettingValue(key: "defaultColor", fallback: 0, defaults: defaults).value == 3, "integer paper color survives reopening")
'''
with tempfile.TemporaryDirectory(prefix='string-notes-settings-test-') as folder:
    path = Path(folder)
    (path / 'main.swift').write_text(checks + '\n' + rows)
    subprocess.run(['xcrun', 'swiftc', '-module-cache-path', '/tmp/string-notes-module-cache', str(root/'Sources/SettingStorage.swift'), str(path/'main.swift'), '-o', str(path/'test')], check=True)
    subprocess.run([str(path/'test')], check=True)
