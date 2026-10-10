import Cocoa
import SwiftUI

// A single original mark: a softly sagging line, one clip, one note.
enum Brand {
    static func menuIcon() -> NSImage {
        let image = NSImage(size: NSSize(width: 26, height: 18), flipped: true) { _ in
            NSColor.black.setStroke()
            // Leave air around the clip rather than crossing three strokes.
            let rope = NSBezierPath(); rope.lineWidth = 1.15; rope.lineCapStyle = .round
            rope.move(to: .init(x: 1, y: 2.5))
            rope.curve(to: .init(x: 10.5, y: 4), controlPoint1: .init(x: 4, y: 3.5), controlPoint2: .init(x: 7, y: 4))
            rope.move(to: .init(x: 15.5, y: 4))
            rope.curve(to: .init(x: 25, y: 2.5), controlPoint1: .init(x: 19, y: 4), controlPoint2: .init(x: 22, y: 3.5)); rope.stroke()
            let paper = NSBezierPath(roundedRect: .init(x: 8, y: 8, width: 10, height: 8), xRadius: 1.5, yRadius: 1.5)
            paper.lineWidth = 1.15; paper.stroke()
            let clip = NSBezierPath(); clip.lineWidth = 1.6; clip.lineCapStyle = .round
            clip.move(to: .init(x: 13, y: 3)); clip.line(to: .init(x: 13, y: 8.5)); clip.stroke()
            let text = NSBezierPath(); text.lineWidth = 1; text.lineCapStyle = .round
            text.move(to: .init(x: 10.5, y: 12)); text.line(to: .init(x: 15.5, y: 12)); text.stroke()
            return true
        }
        image.isTemplate = true; image.accessibilityDescription = L("绳上便笺"); return image
    }
    static func appIcon(size: CGFloat) -> NSImage {
        NSImage(size: NSSize(width: size, height: size), flipped: true) { _ in
            let t = NSAffineTransform(); t.scale(by: size / 1024); t.concat()
            let base = NSBezierPath(roundedRect: NSRect(x: 64, y: 64, width: 896, height: 896), xRadius: 200, yRadius: 200)
            NSGradient(starting: NSColor(red: 0.29, green: 0.43, blue: 0.37, alpha: 1), ending: NSColor(red: 0.12, green: 0.25, blue: 0.22, alpha: 1))!.draw(in: base, angle: 90)
            let rope = NSBezierPath(); rope.lineWidth = 10; rope.lineCapStyle = .round
            rope.move(to: .init(x: 80, y: 285)); rope.curve(to: .init(x: 944, y: 285), controlPoint1: .init(x: 350, y: 365), controlPoint2: .init(x: 670, y: 365))
            NSColor(red: 0.86, green: 0.87, blue: 0.76, alpha: 1).setStroke(); rope.stroke()
            NSGraphicsContext.saveGraphicsState()
            let tilt = NSAffineTransform(); tilt.translateX(by: 512, yBy: 340); tilt.rotate(byDegrees: -6); tilt.translateX(by: -512, yBy: -340); tilt.concat()
            let paper = NSBezierPath(roundedRect: .init(x: 282, y: 337, width: 460, height: 430), xRadius: 22, yRadius: 22)
            let shadow = NSShadow(); shadow.shadowOffset = NSSize(width: 10, height: -20); shadow.shadowBlurRadius = 26; shadow.shadowColor = NSColor.black.withAlphaComponent(0.25); shadow.set()
            NSColor(red: 1, green: 0.91, blue: 0.64, alpha: 1).setFill(); paper.fill()
            NSShadow().set()
            let fold = NSBezierPath(); fold.move(to: .init(x: 672, y: 767)); fold.line(to: .init(x: 742, y: 697)); fold.line(to: .init(x: 742, y: 767)); fold.close()
            NSColor(red: 0.85, green: 0.73, blue: 0.44, alpha: 1).setFill(); fold.fill()
            for (y, length): (CGFloat, CGFloat) in [(495, 255), (562, 195), (629, 220)] {
                let line = NSBezierPath(); line.lineWidth = 18; line.lineCapStyle = .round; line.move(to: .init(x: 361, y: y)); line.line(to: .init(x: 361 + length, y: y)); NSColor(red: 0.39, green: 0.40, blue: 0.27, alpha: 0.68).setStroke(); line.stroke()
            }
            NSGraphicsContext.restoreGraphicsState()
            let clip = NSBezierPath(roundedRect: .init(x: 493, y: 278, width: 38, height: 126), xRadius: 12, yRadius: 12)
            NSGradient(starting: NSColor(white: 0.98, alpha: 1), ending: NSColor(white: 0.62, alpha: 1))!.draw(in: clip, angle: 0)
            NSColor(white: 0.4, alpha: 0.6).setFill(); NSBezierPath(roundedRect: .init(x: 501, y: 329, width: 22, height: 5), xRadius: 2, yRadius: 2).fill()
            return true
        }
    }
}
struct ToolIcon: View {
    let name: String
    var body: some View { Image(systemName: name).font(.system(size: 14, weight: .regular)).frame(width: 20, height: 20) }
}

// Short, interruptible feedback. No animation delays any data operation.
struct TactileButtonStyle: ButtonStyle {
    @AppStorage("reduceMotion") var reduceMotion = false
    @Environment(\.accessibilityReduceMotion) var systemReduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion && !systemReduceMotion ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.78 : 1)
            .animation(reduceMotion || systemReduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
struct HoverRow: ViewModifier {
    @State private var hovering = false
    @AppStorage("reduceMotion") var reduceMotion = false
    @Environment(\.accessibilityReduceMotion) var systemReduceMotion
    func body(content: Content) -> some View {
        content.background(Color.primary.opacity(hovering ? 0.075 : 0.035), in: RoundedRectangle(cornerRadius: 8))
            .onHover { hovering = $0 }
            .animation(reduceMotion || systemReduceMotion ? nil : .easeOut(duration: 0.14), value: hovering)
    }
}
