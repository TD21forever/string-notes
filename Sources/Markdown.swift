import Cocoa

// Presentation only: characters (including syntax and image attachments) never change.
enum MarkdownStyle {
    static func apply(_ storage: NSTextStorage, selection: NSRange, font: NSFont, enabled: Bool) {
        let text = storage.string as NSString
        let all = NSRange(location: 0, length: text.length)
        storage.beginEditing()
        defer { storage.endEditing() }
        for key in [NSAttributedString.Key.font, .foregroundColor, .backgroundColor, .strikethroughStyle, .paragraphStyle, .link, .underlineStyle] { storage.removeAttribute(key, range: all) }
        storage.addAttributes([.font: font, .foregroundColor: NSColor.black.withAlphaComponent(0.82)], range: all)
        guard enabled, text.length > 0 else { return }
        let caret = min(selection.location, text.length)
        let active = text.lineRange(for: NSRange(location: caret, length: 0))
        var protected: [NSRange] = []
        func matches(_ pattern: String, in range: NSRange) -> [NSTextCheckingResult] {
            (try? NSRegularExpression(pattern: pattern)).map { $0.matches(in: storage.string, range: range) } ?? []
        }
        func overlaps(_ a: NSRange, _ b: NSRange) -> Bool { NSIntersectionRange(a, b).length > 0 }
        func marker(_ range: NSRange) {
            guard range.length > 0 else { return }
            let editing = overlaps(range, active) || (selection.length > 0 && overlaps(range, selection))
            storage.addAttribute(.foregroundColor, value: editing ? NSColor.black.withAlphaComponent(0.32) : NSColor.clear, range: range)
            if !editing { storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 0.1), range: range) }
        }
        // Fenced blocks are literal, including Markdown-looking text inside them.
        protected = fencedBlocks(storage.string).map(\.range)
        var offset = 0
        for block in protected {
            storage.addAttributes([.font: NSFont.monospacedSystemFont(ofSize: font.pointSize * 0.92, weight: .regular), .backgroundColor: NSColor.black.withAlphaComponent(0.055)], range: block)
        }
        for match in matches(#"(?<![\\`])`([^`\n]+)`"#, in: all) where !protected.contains(where: { overlaps($0, match.range) }) {
            let body = match.range(at: 1)
            storage.addAttributes([.font: NSFont.monospacedSystemFont(ofSize: font.pointSize * 0.92, weight: .regular), .backgroundColor: NSColor.black.withAlphaComponent(0.065)], range: body)
            marker(NSRange(location: match.range.location, length: 1)); marker(NSRange(location: NSMaxRange(body), length: 1))
            protected.append(match.range)
        }
        offset = 0
        while offset < text.length {
            let line = text.lineRange(for: NSRange(location: offset, length: 0)); offset = NSMaxRange(line)
            guard !protected.contains(where: { $0.location <= line.location && NSMaxRange($0) >= NSMaxRange(line) }) else { continue }
            if let m = matches(#"^(#{1,3})[ \t]+(.+)$"#, in: line).first {
                let size = font.pointSize * [1.65, 1.35, 1.15][m.range(at: 1).length - 1]
                storage.addAttribute(.font, value: NSFont.systemFont(ofSize: size, weight: .semibold), range: m.range(at: 2))
                marker(NSRange(location: m.range.location, length: m.range(at: 2).location - m.range.location))
            }
            if let m = matches(#"^([ \t]*>[ \t]?)(.*)$"#, in: line).first {
                storage.addAttribute(.foregroundColor, value: NSColor.black.withAlphaComponent(0.52), range: m.range(at: 2))
                let paragraph = NSMutableParagraphStyle(); paragraph.firstLineHeadIndent = 12; paragraph.headIndent = 12
                storage.addAttribute(.paragraphStyle, value: paragraph, range: line)
                storage.addAttribute(.foregroundColor, value: NSColor.black.withAlphaComponent(0.3), range: m.range(at: 1))
            }
            if matches(#"^[ \t]*(?:[-+*]|\d+\.)[ \t]+"#, in: line).first != nil {
                let paragraph = NSMutableParagraphStyle(); paragraph.headIndent = font.pointSize * 1.4
                storage.addAttribute(.paragraphStyle, value: paragraph, range: line)
                if let m = matches(#"^[ \t]*[-+*] \[[xX]\] (.*)$"#, in: line).first {
                    storage.addAttributes([.strikethroughStyle: NSUnderlineStyle.single.rawValue, .foregroundColor: NSColor.black.withAlphaComponent(0.45)], range: m.range(at: 1))
                }
            }
        }
        for (pattern, kind, count) in [
            (#"(?<![\\*])\*\*([^*\n]+)\*\*(?!\*)"#, "bold", 2),
            (#"(?<![\\~])~~([^~\n]+)~~"#, "strike", 2),
            (#"(?<![\\*])\*([^*\n]+)\*(?!\*)"#, "italic", 1)
        ] {
            for m in matches(pattern, in: all) where !protected.contains(where: { overlaps($0, m.range) }) {
                let body = m.range(at: 1)
                if kind == "strike" { storage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: body) }
                else {
                    let base = storage.attribute(.font, at: body.location, effectiveRange: nil) as? NSFont ?? font
                    storage.addAttribute(.font, value: NSFontManager.shared.convert(base, toHaveTrait: kind == "bold" ? .boldFontMask : .italicFontMask), range: body)
                }
                marker(NSRange(location: m.range.location, length: count)); marker(NSRange(location: NSMaxRange(body), length: count))
            }
        }
    }
    struct FencedBlock {
        let range: NSRange
        let delimiter: String
        let closed: Bool
    }
    static func fencedBlocks(_ source: String) -> [FencedBlock] {
        let text = source as NSString
        var result: [FencedBlock] = []
        var opening: (start: Int, delimiter: String)?
        var offset = 0
        while offset < text.length {
            let line = text.lineRange(for: NSRange(location: offset, length: 0))
            let value = text.substring(with: line).trimmingCharacters(in: .whitespacesAndNewlines)
            let ticks = String(value.prefix(while: { $0 == "`" }))
            if let start = opening {
                if ticks.count >= start.delimiter.count && value.dropFirst(ticks.count).trimmingCharacters(in: .whitespaces).isEmpty {
                    result.append(FencedBlock(range: NSRange(location: start.start, length: NSMaxRange(line) - start.start), delimiter: start.delimiter, closed: true))
                    opening = nil
                }
            } else if ticks.count >= 3 && !value.dropFirst(ticks.count).contains("`") {
                opening = (offset, ticks)
            }
            offset = NSMaxRange(line)
        }
        if let start = opening {
            result.append(FencedBlock(range: NSRange(location: start.start, length: text.length - start.start), delimiter: start.delimiter, closed: false))
        }
        return result
    }
    static func codeBlock(at caret: Int, in source: String) -> FencedBlock? {
        fencedBlocks(source).first { block in
            caret >= block.range.location && (caret < NSMaxRange(block.range) || (!block.closed && caret == NSMaxRange(block.range)))
        }
    }
    // An empty final line followed by Return closes an unfinished block in one undoable edit.
    static func codeBlockExit(_ source: String, caret: Int) -> String? {
        let text = source as NSString
        guard caret == text.length, let block = codeBlock(at: caret, in: source), !block.closed else { return nil }
        let line = text.lineRange(for: NSRange(location: caret, length: 0))
        guard line.location > block.range.location,
              text.substring(with: line).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return block.delimiter + "\n"
    }
    static func canonical(_ value: NSAttributedString, font: NSFont) -> NSAttributedString {
        let result = NSMutableAttributedString(string: value.string, attributes: [.font: font, .foregroundColor: NSColor.black.withAlphaComponent(0.82)])
        value.enumerateAttribute(.attachment, in: NSRange(location: 0, length: value.length)) { attachment, range, _ in
            if let attachment = attachment { result.addAttribute(.attachment, value: attachment, range: range) }
        }
        return result
    }
    static func nextListPrefix(_ line: String) -> (prefix: String, empty: Bool)? {
        let text = line as NSString
        let pattern = #"^([ \t]*)(?:([-+*])([ \t]+)(?:\[([ xX])\][ \t]+)?|(\d+)\.([ \t]+))(.*)$"#
        guard let m = try? NSRegularExpression(pattern: pattern).firstMatch(in: line, range: NSRange(location: 0, length: text.length)) else { return nil }
        func group(_ i: Int) -> String { m.range(at: i).location == NSNotFound ? "" : text.substring(with: m.range(at: i)) }
        let prefix: String
        if !group(5).isEmpty { guard let n = Int(group(5)), n < Int.max else { return nil }; prefix = group(1) + "\(n + 1). " }
        else { prefix = group(1) + group(2) + " " + (m.range(at: 4).location == NSNotFound ? "" : "[ ] ") }
        return (prefix, group(7).trimmingCharacters(in: .whitespaces).isEmpty)
    }
}
