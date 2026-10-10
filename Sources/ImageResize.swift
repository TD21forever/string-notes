import Cocoa

class ResizableImageTextView: NSTextView {
    private struct ResizeGesture {
        let range: NSRange
        let attachment: NSTextAttachment
        let rect: NSRect
        let start: NSPoint
        let corner: Int
        var width: CGFloat
    }
    private var resizing: ResizeGesture?
    private var availableWidth: CGFloat { max(48, (textContainer?.containerSize.width ?? bounds.width - 40) - 12) }
    private func image(at index: Int) -> NSTextAttachment? {
        guard index >= 0, index < (textStorage?.length ?? 0) else { return nil }
        return textStorage?.attribute(.attachment, at: index, effectiveRange: nil) as? NSTextAttachment
    }
    private func rect(at index: Int) -> NSRect? {
        guard image(at: index) != nil, let layout = layoutManager, let container = textContainer else { return nil }
        layout.ensureLayout(for: container)
        let glyphs = layout.glyphRange(forCharacterRange: NSRange(location: index, length: 1), actualCharacterRange: nil)
        var rect = layout.boundingRect(forGlyphRange: glyphs, in: container)
        rect.origin.x += textContainerOrigin.x; rect.origin.y += textContainerOrigin.y
        return rect
    }
    private func corners(_ rect: NSRect) -> [NSPoint] {
        [NSPoint(x: rect.minX, y: rect.minY), NSPoint(x: rect.maxX, y: rect.minY), NSPoint(x: rect.minX, y: rect.maxY), NSPoint(x: rect.maxX, y: rect.maxY)]
    }
    private func hitImage(_ point: NSPoint) -> Int? {
        guard let storage = textStorage else { return nil }
        var found: Int?
        storage.enumerateAttribute(.attachment, in: NSRange(location: 0, length: storage.length)) { value, range, stop in
            if value != nil, let rect = self.rect(at: range.location), rect.contains(point) { found = range.location; stop.pointee = true }
        }
        return found
    }
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let selection = selectedRange()
        guard selection.length == 1, var frame = rect(at: selection.location) else { return }
        if let gesture = resizing {
            frame.size = NSSize(width: gesture.width, height: gesture.rect.height * gesture.width / max(1, gesture.rect.width))
        }
        NSColor.controlAccentColor.setStroke()
        let border = NSBezierPath(rect: frame); border.lineWidth = 1.5; border.stroke()
        for corner in corners(frame) {
            let handle = NSBezierPath(roundedRect: NSRect(x: corner.x - 4, y: corner.y - 4, width: 8, height: 8), xRadius: 2, yRadius: 2)
            NSColor.white.setFill(); handle.fill(); NSColor.controlAccentColor.setStroke(); handle.stroke()
        }
        if resizing != nil {
            let label = "\(Int(frame.width)) × \(Int(frame.height))"
            label.draw(at: NSPoint(x: frame.minX + 8, y: frame.minY + 8), withAttributes: [.font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium), .foregroundColor: NSColor.white, .backgroundColor: NSColor.controlAccentColor])
        }
    }
    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let selection = selectedRange()
        if selection.length == 1, let attachment = image(at: selection.location), let frame = rect(at: selection.location),
           let corner = corners(frame).firstIndex(where: { NSRect(x: $0.x - 9, y: $0.y - 9, width: 18, height: 18).contains(point) }) {
            resizing = ResizeGesture(range: selection, attachment: attachment, rect: frame, start: point, corner: corner, width: frame.width)
            return
        }
        if let index = hitImage(point) {
            window?.makeFirstResponder(self); setSelectedRange(NSRange(location: index, length: 1)); needsDisplay = true; return
        }
        super.mouseDown(with: event); needsDisplay = true
    }
    override func mouseDragged(with event: NSEvent) {
        guard var gesture = resizing else { super.mouseDragged(with: event); return }
        let point = convert(event.locationInWindow, from: nil)
        let dx = (point.x - gesture.start.x) * (gesture.corner % 2 == 0 ? -1 : 1)
        let dy = (point.y - gesture.start.y) * (gesture.corner < 2 ? -1 : 1)
        let ratio = gesture.rect.height / max(1, gesture.rect.width)
        let delta = (dx + dy * ratio) / (1 + ratio * ratio)
        gesture.width = min(availableWidth, max(48, gesture.rect.width + delta))
        resizing = gesture; needsDisplay = true
    }
    override func mouseUp(with event: NSEvent) {
        guard let gesture = resizing else { super.mouseUp(with: event); return }
        resizing = nil
        if abs(gesture.width - gesture.rect.width) > 0.5 {
            replaceImage(gesture.attachment, at: gesture.range, width: gesture.width)
        }
        needsDisplay = true
    }
    private func replaceImage(_ attachment: NSTextAttachment, at range: NSRange, width: CGFloat) {
        guard let replacement = NoteDocument.resized(attachment, desiredWidth: width, available: availableWidth) else { return }
        // Native text replacement makes a whole resize one undoable edit and triggers autosave.
        insertText(replacement, replacementRange: range)
        setSelectedRange(range); undoManager?.setActionName("调整图片大小"); needsDisplay = true
    }
    @objc private func fitSelectedImage(_ sender: Any?) { resizeSelected(width: 0) }
    @objc private func originalImageSize(_ sender: Any?) {
        guard let attachment = image(at: selectedRange().location), let data = attachment.fileWrapper?.regularFileContents, let image = NSImage(data: data) else { return }
        resizeSelected(width: image.size.width)
    }
    private func resizeSelected(width: CGFloat) {
        guard selectedRange().length == 1, let attachment = image(at: selectedRange().location) else { return }
        replaceImage(attachment, at: selectedRange(), width: width)
    }
    override func menu(for event: NSEvent) -> NSMenu? {
        if let index = hitImage(convert(event.locationInWindow, from: nil)) { setSelectedRange(NSRange(location: index, length: 1)) }
        let menu = super.menu(for: event) ?? NSMenu()
        if selectedRange().length == 1, image(at: selectedRange().location) != nil {
            menu.addItem(.separator())
            for (title, action) in [("适应便笺宽度", #selector(fitSelectedImage(_:))), ("恢复原始大小", #selector(originalImageSize(_:)))] {
                let item = NSMenuItem(title: title, action: action, keyEquivalent: ""); item.target = self; menu.addItem(item)
            }
        }
        return menu
    }
    override func resignFirstResponder() -> Bool { resizing = nil; needsDisplay = true; return super.resignFirstResponder() }
}
