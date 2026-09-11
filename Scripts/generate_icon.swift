import AppKit
import CoreGraphics

func renderFoldedCircleIcon(size: CGSize) -> NSImage {
    let image = NSImage(size: size)
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let scale = size.width / 1024.0
    let w = size.width
    let h = size.height

    // 1. Squircle geometry (macOS standard proportions)
    let squircleSize: CGFloat = 824.0 * scale
    let squircleOrigin = CGPoint(x: (w - squircleSize) / 2.0, y: (h - squircleSize) / 2.0)
    let squircleRect = CGRect(origin: squircleOrigin, size: CGSize(width: squircleSize, height: squircleSize))
    let cornerRadius: CGFloat = 185.0 * scale

    // 2. Drop Shadow for Squircle
    ctx.saveGState()
    let shadowColor = NSColor.black.withAlphaComponent(0.40).cgColor
    ctx.setShadow(offset: CGSize(width: 0, height: -22.0 * scale), blur: 38.0 * scale, color: shadowColor)

    let squirclePath = CGPath(roundedRect: squircleRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.addPath(squirclePath)
    ctx.setFillColor(NSColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1.0).cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // 3. Squircle Gradient Fill & Micro-border
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.clip()

    let colors = [
        NSColor(white: 0.12, alpha: 1.0).cgColor,
        NSColor(white: 0.06, alpha: 1.0).cgColor
    ] as CFArray
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(
            gradient,
            start: CGPoint(x: w / 2, y: squircleRect.maxY),
            end: CGPoint(x: w / 2, y: squircleRect.minY),
            options: []
        )
    }

    // Top inner ambient highlight
    let innerHighlightPath = CGPath(roundedRect: squircleRect.insetBy(dx: 2 * scale, dy: 2 * scale), cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.addPath(innerHighlightPath)
    ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.09).cgColor)
    ctx.setLineWidth(2.0 * scale)
    ctx.strokePath()

    // 4. THE GLOWING FOLDED CIRCLE (Clippo Motif)
    let center = CGPoint(x: w / 2.0, y: h / 2.0)
    let r: CGFloat = 220.0 * scale
    let strokeWidth: CGFloat = 26.0 * scale

    // Full Glowing Circle
    let fullCircleRect = CGRect(x: center.x - r, y: center.y - r, width: r * 2.0, height: r * 2.0)
    let fullCirclePath = CGPath(ellipseIn: fullCircleRect, transform: nil)

    // Outer Glow for Full Circle
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 28.0 * scale, color: NSColor.white.withAlphaComponent(0.50).cgColor)
    ctx.addPath(fullCirclePath)
    ctx.setStrokeColor(NSColor.white.cgColor)
    ctx.setLineWidth(strokeWidth)
    ctx.strokePath()
    ctx.restoreGState()

    // Crisp Core for Full Circle
    ctx.saveGState()
    ctx.addPath(fullCirclePath)
    ctx.setStrokeColor(NSColor(white: 0.98, alpha: 1.0).cgColor)
    ctx.setLineWidth(strokeWidth)
    ctx.strokePath()
    ctx.restoreGState()

    // 5. The Top Fold Flap
    // Crease line between leftAngle (124°) and rightAngle (56°)
    let leftAngle = CGFloat(124.0 * .pi / 180.0)
    let rightAngle = CGFloat(56.0 * .pi / 180.0)
    let leftPt = CGPoint(x: center.x + r * cos(leftAngle), y: center.y + r * sin(leftAngle))
    let rightPt = CGPoint(x: center.x + r * cos(rightAngle), y: center.y + r * sin(rightAngle))

    let crease = CGMutablePath()
    crease.move(to: leftPt)
    crease.addLine(to: rightPt)

    // Flap downward fold curve
    let foldApex = CGPoint(x: center.x, y: center.y + r * 0.38)
    let foldFlap = CGMutablePath()
    foldFlap.move(to: leftPt)
    foldFlap.addQuadCurve(to: rightPt, control: foldApex)

    // Flap Interior Fill (subtle darker plane with depth)
    let flapClosedPath = CGMutablePath()
    flapClosedPath.move(to: leftPt)
    flapClosedPath.addQuadCurve(to: rightPt, control: foldApex)
    flapClosedPath.addLine(to: rightPt)
    flapClosedPath.addArc(center: center, radius: r, startAngle: rightAngle, endAngle: leftAngle, clockwise: false)
    flapClosedPath.closeSubpath()

    ctx.saveGState()
    ctx.addPath(flapClosedPath)
    ctx.setFillColor(NSColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 0.85).cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // Soft Drop Shadow under Fold Flap
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -14.0 * scale), blur: 18.0 * scale, color: NSColor.black.withAlphaComponent(0.90).cgColor)
    ctx.addPath(foldFlap)
    ctx.setStrokeColor(NSColor(red: 0.05, green: 0.05, blue: 0.06, alpha: 1.0).cgColor)
    ctx.setLineWidth(strokeWidth + 6 * scale)
    ctx.strokePath()
    ctx.restoreGState()

    // Flap Outer Glow
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 24.0 * scale, color: NSColor.white.withAlphaComponent(0.65).cgColor)
    ctx.addPath(foldFlap)
    ctx.setStrokeColor(NSColor.white.cgColor)
    ctx.setLineWidth(strokeWidth)
    ctx.setLineCap(.round)
    ctx.strokePath()
    ctx.restoreGState()

    // Flap Crisp Core
    ctx.saveGState()
    ctx.addPath(foldFlap)
    ctx.setStrokeColor(NSColor(white: 1.0, alpha: 1.0).cgColor)
    ctx.setLineWidth(strokeWidth)
    ctx.setLineCap(.round)
    ctx.strokePath()
    ctx.restoreGState()

    // Elegant Crease Line
    ctx.saveGState()
    ctx.addPath(crease)
    ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.35).cgColor)
    ctx.setLineWidth(2.0 * scale)
    ctx.setLineDash(phase: 0, lengths: [6.0 * scale, 5.0 * scale])
    ctx.strokePath()
    ctx.restoreGState()

    ctx.restoreGState() // squircle clip
    image.unlockFocus()
    return image
}

// Generate 1024x1024
let icon1024 = renderFoldedCircleIcon(size: CGSize(width: 1024, height: 1024))
if let tiff = icon1024.tiffRepresentation,
   let rep = NSBitmapImageRep(data: tiff),
   let pngData = rep.representation(using: .png, properties: [:]) {
    let assetsURL = URL(fileURLWithPath: "assets/app_icon_1024.png")
    try! pngData.write(to: assetsURL)
    let resURL = URL(fileURLWithPath: "Resources/AppIcon.png")
    try! pngData.write(to: resURL)
    print("Saved 1024x1024 icon to assets/app_icon_1024.png and Resources/AppIcon.png")
}

// Generate .iconset for .icns
let fileManager = FileManager.default
let iconsetDir = URL(fileURLWithPath: "clippo.iconset")
try? fileManager.removeItem(at: iconsetDir)
try! fileManager.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

let sizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (filename, s) in sizes {
    let img = renderFoldedCircleIcon(size: CGSize(width: s, height: s))
    if let tiff = img.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let data = rep.representation(using: .png, properties: [:]) {
        try! data.write(to: iconsetDir.appendingPathComponent(filename))
    }
}

// Run iconutil
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", "clippo.iconset", "-o", "Resources/AppIcon.icns"]
try! process.run()
process.waitUntilExit()

try? fileManager.removeItem(at: iconsetDir)
print("Successfully generated Resources/AppIcon.icns")
