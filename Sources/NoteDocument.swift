import Cocoa

// Self-contained RTFD keeps inline images inside the atomic notebook backup.
enum NoteDocument {
    static func decode(_ note: Memo) -> NSAttributedString {
        if let data = note.richText, let value = NSAttributedString(rtfd: data, documentAttributes: nil) { return value }
        return NSAttributedString(string: note.text, attributes: [.font: NSFont.systemFont(ofSize: 17), .foregroundColor: NSColor.black.withAlphaComponent(0.82)])
    }
    static func encode(_ value: NSAttributedString) -> Data? {
        value.rtfd(from: NSRange(location: 0, length: value.length), documentAttributes: [:])
    }
    static func image(_ image: NSImage, width: CGFloat) -> NSAttributedString? {
        guard image.size.width > 0, image.size.height > 0,
              let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else { return nil }
        let file = FileWrapper(regularFileWithContents: png); file.preferredFilename = "snimg_" + UUID().uuidString + "_w" + String(Int(min(image.size.width, max(48, width)))) + ".png"
        let attachment = NSTextAttachment(fileWrapper: file)
        let display = image.copy() as! NSImage
        let scale = min(1, max(80, width) / display.size.width)
        display.size = NSSize(width: display.size.width * scale, height: display.size.height * scale)
        attachment.attachmentCell = NSTextAttachmentCell(imageCell: display)
        return NSAttributedString(attachment: attachment)
    }
    static func fitImages(_ storage: NSTextStorage, width: CGFloat) {
        storage.enumerateAttribute(.attachment, in: NSRange(location: 0, length: storage.length)) { value, _, _ in
            guard let attachment = value as? NSTextAttachment,
                  let data = attachment.fileWrapper?.regularFileContents,
                  let image = NSImage(data: data), image.size.width > 0 else { return }
            let desired = preferredWidth(attachment) ?? min(image.size.width, 320)
            let target = desired == 0 ? width : desired
            let scale = max(1, min(width, target)) / image.size.width
            image.size = NSSize(width: image.size.width * scale, height: image.size.height * scale)
            attachment.attachmentCell = NSTextAttachmentCell(imageCell: image)
        }
    }
    // Width is stored in the attachment filename, which RTFD carries through copy and backup.
    // 0 means fit-to-window. Older untagged attachments use a conservative 320-point width.
    static func preferredWidth(_ attachment: NSTextAttachment) -> CGFloat? {
        let name = attachment.fileWrapper?.preferredFilename ?? attachment.fileWrapper?.filename ?? ""
        guard let range = name.range(of: #"_w[0-9]+\.png$"#, options: .regularExpression),
              let value = Double(name[range].dropFirst(2).dropLast(4)) else { return nil }
        return CGFloat(value)
    }
    static func resized(_ attachment: NSTextAttachment, desiredWidth: CGFloat, available: CGFloat) -> NSAttributedString? {
        guard let data = attachment.fileWrapper?.regularFileContents, let image = NSImage(data: data) else { return nil }
        let file = FileWrapper(regularFileWithContents: data)
        file.preferredFilename = "snimg_" + UUID().uuidString + "_w" + String(Int(max(0, min(10000, desiredWidth)))) + ".png"
        let result = NSTextAttachment(fileWrapper: file)
        let width = min(max(1, available), desiredWidth == 0 ? available : max(1, desiredWidth))
        image.size = NSSize(width: width, height: image.size.height * width / image.size.width)
        result.attachmentCell = NSTextAttachmentCell(imageCell: image)
        return NSAttributedString(attachment: result)
    }
    static func preview(_ note: Memo) -> String {
        note.text.replacingOccurrences(of: "\u{fffc}", with: "[图片]")
    }
}
