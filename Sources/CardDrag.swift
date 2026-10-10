import Cocoa
import SwiftUI

// Track the full mouse sequence so a click and a pull cannot both open the note.
final class CardDragView: NSView {
    var hovered: (Bool) -> Void = { _ in }
    private var hoverArea: NSTrackingArea?
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let area = hoverArea { removeTrackingArea(area) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self)
        addTrackingArea(area); hoverArea = area
    }
    override func mouseEntered(with event: NSEvent) { hovered(true) }
    override func mouseExited(with event: NSEvent) { hovered(false) }
    override func resetCursorRects() { addCursorRect(bounds, cursor: .openHand) }
    var clicked: () -> Void = {}
    var moved: (NSPoint?) -> Void = { _ in }
    var dropped: (NSPoint) -> Void = { _ in }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) {
        guard let window = window else { return }
        let start = window.convertPoint(toScreen: event.locationInWindow)
        var dragging = false
        while let next = window.nextEvent(matching: [.leftMouseDragged, .leftMouseUp, .keyDown]) {
            if next.type == .keyDown {
                if next.keyCode == 53 { moved(nil); return }
                continue
            }
            let point = window.convertPoint(toScreen: next.locationInWindow)
            if hypot(point.x - start.x, point.y - start.y) > 6 { dragging = true }
            if next.type == .leftMouseUp {
                if dragging {
                    let complete = dropped, finish = moved
                    DispatchQueue.main.async { complete(point); finish(nil) }
                } else { clicked(); moved(nil) }
                return
            }
            if dragging { moved(point) }
        }
        moved(nil)
    }
    override func accessibilityPerformPress() -> Bool { clicked(); return true }
}
struct CardDragSurface: NSViewRepresentable {
    let title: String
    let hovered: (Bool) -> Void
    let clicked: () -> Void
    let moved: (NSPoint?) -> Void
    let dropped: (NSPoint) -> Void
    func makeNSView(context: Context) -> CardDragView { CardDragView() }
    func updateNSView(_ view: CardDragView, context: Context) {
        view.hovered = hovered
        view.clicked = clicked; view.moved = moved; view.dropped = dropped
        view.setAccessibilityElement(true); view.setAccessibilityRole(.button)
        view.setAccessibilityLabel(title)
        view.setAccessibilityHelp("点击打开；向下拖取下，沿绳拖动排序")
    }
}

extension Notification.Name {
    static let noteWindowDrag = Notification.Name("StringNotes.windowDrag")
}
final class NoteWindowDragView: NSView {
    override var mouseDownCanMoveWindow: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) {
        guard let window = window else { return }
        let start = window.convertPoint(toScreen: event.locationInWindow)
        let origin = window.frame.origin
        var dragged = false
        while let next = window.nextEvent(matching: [.leftMouseDragged, .leftMouseUp]) {
            let point = window.convertPoint(toScreen: next.locationInWindow)
            if next.type == .leftMouseUp {
                if dragged { NotificationCenter.default.post(name: .noteWindowDrag, object: window, userInfo: ["point": point, "ended": true]) }
                return
            }
            dragged = true
            window.setFrameOrigin(NSPoint(x: origin.x + point.x - start.x, y: origin.y + point.y - start.y))
            NotificationCenter.default.post(name: .noteWindowDrag, object: window, userInfo: ["point": point, "ended": false])
        }
    }
    override func resetCursorRects() { addCursorRect(bounds, cursor: .openHand) }
}
struct NoteWindowDragSurface: NSViewRepresentable {
    func makeNSView(context: Context) -> NoteWindowDragView { NoteWindowDragView() }
    func updateNSView(_ view: NoteWindowDragView, context: Context) {}
}
