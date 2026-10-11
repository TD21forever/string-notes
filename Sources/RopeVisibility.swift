import Foundation

/// Manual dismissal must survive a pointer left over the menu bar.
struct RopeVisibilityPolicy {
    private var waitingForMenuBarExit = false
    private var hoverSince: Date?
    private var cooldownUntil = Date.distantPast

    mutating func hide(automatic: Bool, hasEditors: Bool, mousePressed: Bool, dragging: Bool, now: Date = Date()) -> Bool {
        guard !dragging else { return false }
        if automatic && (hasEditors || mousePressed) { return false }
        waitingForMenuBarExit = !automatic
        hoverSince = nil
        cooldownUntil = now.addingTimeInterval(0.7)
        return true
    }

    mutating func didShow() {
        waitingForMenuBarExit = false
        hoverSince = nil
    }

    mutating func trackMenuBar(_ inside: Bool) {
        if !inside {
            waitingForMenuBarExit = false
            hoverSince = nil
        }
    }

    mutating func shouldReveal(inMenuBar: Bool, mousePressed: Bool, enabled: Bool, now: Date = Date()) -> Bool {
        guard inMenuBar, !waitingForMenuBarExit, !mousePressed, enabled, now > cooldownUntil else {
            hoverSince = nil
            return false
        }
        guard let since = hoverSince else { hoverSince = now; return false }
        return now.timeIntervalSince(since) > 0.3
    }
}
