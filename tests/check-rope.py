from pathlib import Path
import subprocess, tempfile
root = Path(__file__).resolve().parents[1]
checks = r'''
import Foundation
func check(_ value: Bool, _ name: String) { precondition(value, name); print("PASS: " + name) }
let a = UUID(), b = UUID(), c = UUID()
let base: [UUID: CGFloat] = [a: 200, b: 600]
let free = RopePlacement.inserting(c, at: 397, into: base)
check(free.positions[c] == 397 && free.positions[a] == 200 && free.positions[b] == 600, "free drop keeps exact location and distant cards")
let tight = RopePlacement.inserting(c, at: 250, into: [a: 100, b: 290])
check(tight.positions[c] == 250 && tight.positions[a] == 440 && tight.positions[b] == 630, "crowded drop preserves pointer position and moves neighbours right")
let crowded = RopePlacement.inserting(c, at: 610, into: base)
check(crowded.positions[c] == 610 && crowded.positions[b] == 420, "overlapping neighbour gives way")
let saved = Dictionary(uniqueKeysWithValues: free.positions.map { ($0.key.uuidString, Double($0.value / 1000)) })
let reload = RopePlacement.positions(ids: free.order, saved: saved, width: 1000)
check(reload == free.positions, "layout does not jump after drop")
let smaller = RopePlacement.positions(ids: free.order, saved: saved, width: 500)
check(smaller.values.min()! >= 100, "smaller display keeps edge margin")
for pair in zip(free.order, free.order.dropFirst()) {
    check(smaller[pair.1]! - smaller[pair.0]! >= 190, "smaller display preserves non-overlapping cards")
}
check(RopePlacement.maxScroll(smaller, width: 500) > 0, "overflow remains reachable by scrolling")
check(DisplayChoice.resolve("mouse", available: ["main", "external"], mouse: "external") == "external", "follow pointer selects its display")
check(DisplayChoice.resolve("external", available: ["main", "external"], mouse: "main") == "external", "fixed display ignores pointer")
check(DisplayChoice.resolve("main", available: ["primary", "external"], mouse: "external") == "primary", "main display uses screen order, not keyboard focus")
check(DisplayChoice.resolve("external", available: ["primary"], mouse: "primary") == "primary", "disconnected display falls back")
check(DisplayChoice.resolve("external", available: ["primary", "external"], mouse: "primary") == "external", "reconnected display restores selection")
check(DisplayChoice.resolve("mouse", available: [], mouse: nil) == nil, "no display is safe")
let start = Date(timeIntervalSince1970: 100)
var policy = RopeVisibilityPolicy()
check(!policy.hide(automatic: true, hasEditors: false, mousePressed: false, dragging: false, autoHide: false), "never hide blocks automatic collapse")
check(policy.hide(automatic: false, hasEditors: false, mousePressed: false, dragging: false, autoHide: false), "never hide still allows manual collapse")
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
    subprocess.run(['xcrun','swiftc','-module-cache-path','/tmp/string-notes-module-cache',str(root/'Sources/RopeVisibility.swift'),str(root/'Sources/RopePlacement.swift'),str(root/'Sources/DisplayPreferences.swift'),str(path/'main.swift'),'-o',str(path/'test')],check=True)
    subprocess.run([str(path/'test')],check=True)
