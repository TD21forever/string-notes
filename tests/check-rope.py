from pathlib import Path
import subprocess, tempfile
root = Path(__file__).resolve().parents[1]
checks = r'''
import Foundation
func check(_ value: Bool, _ name: String) { precondition(value, name); print("PASS: " + name) }
let start = Date(timeIntervalSince1970: 100)
var policy = RopeVisibilityPolicy()
check(policy.hide(automatic: false, hasEditors: true, mousePressed: true, dragging: false, now: start), "manual collapse works with editor and mouse-up timing")
for seconds in [1.0, 2, 30] {
    check(!policy.shouldReveal(inMenuBar: true, mousePressed: false, enabled: true, now: start.addingTimeInterval(seconds)), "staying in menu bar never reopens after manual collapse")
}
policy.trackMenuBar(false)
check(!policy.shouldReveal(inMenuBar: true, mousePressed: false, enabled: true, now: start.addingTimeInterval(31)), "returning starts fresh dwell")
check(policy.shouldReveal(inMenuBar: true, mousePressed: false, enabled: true, now: start.addingTimeInterval(31.4)), "hover returns after leaving menu bar")
check(!policy.hide(automatic: true, hasEditors: true, mousePressed: false, dragging: false), "automatic hide preserves editing")
check(!policy.hide(automatic: true, hasEditors: false, mousePressed: true, dragging: false), "automatic hide preserves mouse operation")
check(!policy.hide(automatic: false, hasEditors: false, mousePressed: false, dragging: true), "active card drag remains protected")
check(policy.hide(automatic: true, hasEditors: false, mousePressed: false, dragging: false, now: start), "automatic hide outside rope")
check(!policy.shouldReveal(inMenuBar: true, mousePressed: false, enabled: true, now: start.addingTimeInterval(0.2)), "automatic hide cooldown")
policy.didShow()
check(!policy.shouldReveal(inMenuBar: true, mousePressed: false, enabled: false, now: start.addingTimeInterval(40)), "disabled hover respected")
check(!policy.shouldReveal(inMenuBar: true, mousePressed: true, enabled: true, now: start.addingTimeInterval(40)), "held mouse cannot hover reveal")
check(!policy.shouldReveal(inMenuBar: true, mousePressed: false, enabled: true, now: start.addingTimeInterval(41)), "manual show clears stale dwell")
check(policy.shouldReveal(inMenuBar: true, mousePressed: false, enabled: true, now: start.addingTimeInterval(41.4)), "manual show clears suppression")
'''
with tempfile.TemporaryDirectory(prefix='string-notes-rope-test-') as folder:
    path = Path(folder)
    (path/'main.swift').write_text(checks)
    subprocess.run(['xcrun','swiftc','-module-cache-path','/tmp/string-notes-module-cache',str(root/'Sources/RopeVisibility.swift'),str(path/'main.swift'),'-o',str(path/'test')],check=True)
    subprocess.run([str(path/'test')],check=True)
