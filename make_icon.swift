import AppKit

let output = CommandLine.arguments[1]
let iconset = URL(fileURLWithPath: output, isDirectory: true)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

func drawIcon() {
    let background = NSBezierPath(roundedRect: NSRect(x: 35, y: 35, width: 954, height: 954), xRadius: 215, yRadius: 215)
    NSGradient(colors: [NSColor(calibratedRed: 0.34, green: 0.36, blue: 0.96, alpha: 1),
                        NSColor(calibratedRed: 0.48, green: 0.27, blue: 0.83, alpha: 1)])!
        .draw(in: background, angle: 45)

    let card = NSBezierPath(roundedRect: NSRect(x: 210, y: 260, width: 604, height: 520), xRadius: 58, yRadius: 58)
    NSColor.white.setFill()
    card.fill()
    NSColor(calibratedWhite: 0.87, alpha: 1).setStroke()
    card.lineWidth = 5
    card.stroke()

    let picture = NSBezierPath(roundedRect: NSRect(x: 246, y: 296, width: 532, height: 448), xRadius: 34, yRadius: 34)
    NSColor(calibratedRed: 0.82, green: 0.92, blue: 1, alpha: 1).setFill()
    picture.fill()

    NSColor(calibratedRed: 1, green: 0.73, blue: 0.29, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: 600, y: 535, width: 100, height: 100)).fill()

    let farHill = NSBezierPath()
    farHill.move(to: NSPoint(x: 246, y: 440))
    farHill.line(to: NSPoint(x: 390, y: 585))
    farHill.line(to: NSPoint(x: 494, y: 480))
    farHill.line(to: NSPoint(x: 600, y: 570))
    farHill.line(to: NSPoint(x: 700, y: 455))
    farHill.line(to: NSPoint(x: 778, y: 520))
    farHill.line(to: NSPoint(x: 778, y: 296))
    farHill.line(to: NSPoint(x: 246, y: 296))
    farHill.close()
    NSColor(calibratedRed: 0.35, green: 0.69, blue: 0.75, alpha: 1).setFill()
    farHill.fill()

    let nearHill = NSBezierPath()
    nearHill.move(to: NSPoint(x: 246, y: 380))
    nearHill.curve(to: NSPoint(x: 778, y: 360), controlPoint1: NSPoint(x: 400, y: 500), controlPoint2: NSPoint(x: 610, y: 290))
    nearHill.line(to: NSPoint(x: 778, y: 296))
    nearHill.line(to: NSPoint(x: 246, y: 296))
    nearHill.close()
    NSColor(calibratedRed: 0.23, green: 0.67, blue: 0.49, alpha: 1).setFill()
    nearHill.fill()

    // Small conversion arrows at the lower edge of the image tile.
    NSColor.white.setStroke()
    let arrow = NSBezierPath()
    arrow.lineWidth = 19
    arrow.lineCapStyle = .round
    arrow.move(to: NSPoint(x: 390, y: 220))
    arrow.line(to: NSPoint(x: 630, y: 220))
    arrow.stroke()
    let head = NSBezierPath()
    head.move(to: NSPoint(x: 630, y: 220))
    head.line(to: NSPoint(x: 586, y: 254))
    head.line(to: NSPoint(x: 586, y: 186))
    head.close()
    NSColor.white.setFill()
    head.fill()
}

let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024)
]

for (filename, pixels) in sizes {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high
    context.cgContext.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)
    drawIcon()
    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    let data = rep.representation(using: .png, properties: [:])!
    try data.write(to: iconset.appendingPathComponent(filename))
}
