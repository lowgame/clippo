import AppKit
import CoreGraphics

func createSquircleBase(ctx: CGContext, w: CGFloat, h: CGFloat, scale: CGFloat) -> (CGRect, CGPath) {
    let squircleSize: CGFloat = 824.0 * scale
    let squircleOrigin = CGPoint(x: (w - squircleSize) / 2.0, y: (h - squircleSize) / 2.0)
    let squircleRect = CGRect(origin: squircleOrigin, size: CGSize(width: squircleSize, height: squircleSize))
    let cornerRadius: CGFloat = 185.0 * scale

    // Drop shadow
    ctx.saveGState()
    let shadowColor = NSColor.black.withAlphaComponent(0.40).cgColor
    ctx.setShadow(offset: CGSize(width: 0, height: -22.0 * scale), blur: 38.0 * scale, color: shadowColor)

    let squirclePath = CGPath(roundedRect: squircleRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.addPath(squirclePath)
    ctx.setFillColor(NSColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1.0).cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // Clip & Gradient Fill
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

    return (squircleRect, squirclePath)
}

func renderPerfectFoldedCircle() -> NSImage {
    let size = CGSize(width: 1024, height: 1024)
    let image = NSImage(size: size)
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else { return image }
    let w: CGFloat = 1024
    let h: CGFloat = 1024

    let (_, _) = createSquircleBase(ctx: ctx, w: w, h: h, scale: 1.0)

    let center = CGPoint(x: w / 2.0, y: h / 2.0)
    let r: CGFloat = 220.0
    let strokeWidth: CGFloat = 26.0

    // Angles for the fold:
    // Left fold point: 125 degrees
    // Right fold point: 55 degrees
    let rightAngle = CGFloat(55.0 * .pi / 180.0)
    let leftAngle = CGFloat(125.0 * .pi / 180.0)

    let leftPt = CGPoint(x: center.x + r * cos(leftAngle), y: center.y + r * sin(leftAngle))
    let rightPt = CGPoint(x: center.x + r * cos(rightAngle), y: center.y + r * sin(rightAngle))

    // 1. Main circle arc: from rightAngle (55°) counter-clockwise (passing 0°, 270°, 180°) to leftAngle (125°)
    // In CGContext where flipped: false (0 is right, 90 is top, 180 is left, 270 is bottom)
    // To sweep around the bottom: start at leftAngle (125°), increase angle (180° -> 270° -> 360°/0° -> 55°) => clockwise: false!
    let mainArc = CGMutablePath()
    mainArc.addArc(center: center, radius: r, startAngle: leftAngle, endAngle: rightAngle, clockwise: false)

    // 2. Folded flap at top:
    // It dips down into the circle, smoothly connecting leftPt and rightPt
    let foldApex = CGPoint(x: center.x, y: center.y + r * 0.44)
    let foldPath = CGMutablePath()
    foldPath.move(to: leftPt)
    foldPath.addQuadCurve(to: rightPt, control: foldApex)

    // 3. Crease dashed / subtle line connecting leftPt to rightPt
    let creasePath = CGMutablePath()
    creasePath.move(to: leftPt)
    creasePath.addLine(to: rightPt)

    // A. Main Arc Glow
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 28.0, color: NSColor.white.withAlphaComponent(0.50).cgColor)
    ctx.addPath(mainArc)
    ctx.setStrokeColor(NSColor.white.cgColor)
    ctx.setLineWidth(strokeWidth)
    ctx.strokePath()
    ctx.restoreGState()

    // B. Main Arc Crisp Core
    ctx.saveGState()
    ctx.addPath(mainArc)
    ctx.setStrokeColor(NSColor(white: 0.98, alpha: 1.0).cgColor)
    ctx.setLineWidth(strokeWidth)
    ctx.strokePath()
    ctx.restoreGState()

    // C. Deep Shadow under Fold Flap
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 18.0, color: NSColor.black.withAlphaComponent(0.85).cgColor)
    ctx.addPath(foldPath)
    ctx.setStrokeColor(NSColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1.0).cgColor)
    ctx.setLineWidth(strokeWidth + 8)
    ctx.strokePath()
    ctx.restoreGState()

    // D. Fold Flap Glow
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 26.0, color: NSColor.white.withAlphaComponent(0.65).cgColor)
    ctx.addPath(foldPath)
    ctx.setStrokeColor(NSColor.white.cgColor)
    ctx.setLineWidth(strokeWidth)
    ctx.setLineCap(.round)
    ctx.strokePath()
    ctx.restoreGState()

    // E. Fold Flap Crisp Core
    ctx.saveGState()
    ctx.addPath(foldPath)
    ctx.setStrokeColor(NSColor(white: 1.0, alpha: 1.0).cgColor)
    ctx.setLineWidth(strokeWidth)
    ctx.setLineCap(.round)
    ctx.strokePath()
    ctx.restoreGState()

    // F. Crease Line (Subtle Fold Accent)
    ctx.saveGState()
    ctx.addPath(creasePath)
    ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.35).cgColor)
    ctx.setLineWidth(2.5)
    ctx.setLineDash(phase: 0, lengths: [6, 5])
    ctx.strokePath()
    ctx.restoreGState()

    ctx.restoreGState() // squircle clip
    image.unlockFocus()
    return image
}

let img = renderPerfectFoldedCircle()
if let tiff = img.tiffRepresentation,
   let rep = NSBitmapImageRep(data: tiff),
   let data = rep.representation(using: .png, properties: [:]) {
    try! data.write(to: URL(fileURLWithPath: "assets/folded_circle_perfect.png"))
    print("Saved to assets/folded_circle_perfect.png")
}
