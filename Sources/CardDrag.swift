import Cocoa
import SwiftUI

// Track the full mouse sequence so a click and a pull cannot both open the note.
final class CardDragView: NSView {
    var clicked: () -> Void = {}
    var moved: (NSPoint?) -> Void = { _ in }
    var dropped: (NSPoint) -> Void = { _ in }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) {
        guard let window = window else { return }
        let start = NSEvent.mouseLocation
        var dragging = false
        while let next = window.nextEvent(matching: [.leftMouseDragged, .leftMouseUp, .keyDown]) {
            if next.type == .keyDown {
                if next.keyCode == 53 { moved(nil); return }
                continue
            }
            let point = NSEvent.mouseLocation
            if hypot(point.x - start.x, point.y - start.y) > 6 { dragging = true }
            if next.type == .leftMouseUp {
                if dragging { dropped(point) } else { clicked() }
                moved(nil)
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
    let clicked: () -> Void
    let moved: (NSPoint?) -> Void
    let dropped: (NSPoint) -> Void
    func makeNSView(context: Context) -> CardDragView { CardDragView() }
    func updateNSView(_ view: CardDragView, context: Context) {
        view.clicked = clicked; view.moved = moved; view.dropped = dropped
        view.setAccessibilityElement(true); view.setAccessibilityRole(.button)
        view.setAccessibilityLabel(title)
        view.setAccessibilityHelp("点击打开；向下拖取下，沿绳拖动排序")
    }
}

final class NoteWindowDragView: NSView {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) {
        guard let window = window else { return }
        let start = NSEvent.mouseLocation
        let origin = window.frame.origin
        while let next = window.nextEvent(matching: [.leftMouseDragged, .leftMouseUp]) {
            if next.type == .leftMouseUp { return }
            let point = NSEvent.mouseLocation
            window.setFrameOrigin(NSPoint(x: origin.x + point.x - start.x, y: origin.y + point.y - start.y))
        }
    }
    override func resetCursorRects() { addCursorRect(bounds, cursor: .openHand) }
}
struct NoteWindowDragSurface: NSViewRepresentable {
    func makeNSView(context: Context) -> NoteWindowDragView { NoteWindowDragView() }
    func updateNSView(_ view: NoteWindowDragView, context: Context) {}
}
