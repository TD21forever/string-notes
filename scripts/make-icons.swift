import Cocoa
let root = URL(fileURLWithPath: CommandLine.arguments[1])
let set = root.appendingPathComponent("AppIcon.iconset")
try FileManager.default.createDirectory(at: set, withIntermediateDirectories: true)
func write(_ image: NSImage, _ size: Int, _ url: URL, height: Int? = nil) throws {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: height ?? size, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: size, height: height ?? size)); NSGraphicsContext.restoreGraphicsState()
    try rep.representation(using: .png, properties: [:])!.write(to: url)
}
for points in [16,32,128,256,512] {
    for scale in [1,2] {
        let pixels = points * scale
        try write(Brand.appIcon(size: CGFloat(pixels)), pixels, set.appendingPathComponent("icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"))
    }
}
try write(Brand.appIcon(size: 1024), 1024, root.appendingPathComponent("app-icon.png"))
try write(Brand.menuIcon(), 52, root.appendingPathComponent("menu-icon.png"), height: 36)
