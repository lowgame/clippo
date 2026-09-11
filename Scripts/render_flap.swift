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

func renderFlapFoldedCircle() -> NSImage {
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

    // Full Glowing Circle
    let fullCircleRect = CGRect(x: center.x - r, y: center.y - r, width: r * 2.0, height: r * 2.0)
    let fullCirclePath = CGPath(ellipseIn: fullCircleRect, transform: nil)

    // 1. Glow for full circle
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 28.0, color: NSColor.white.withAlphaComponent(0.48).cgColor)
    ctx.addPath(fullCirclePath)
    ctx.setStrokeColor(NSColor.white.cgColor)
    ctx.setLineWidth(strokeWidth)
    ctx.strokePath()
    ctx.restoreGState()

    // 2. Crisp core for full circle
    ctx.saveGState()
    ctx.addPath(fullCirclePath)
    ctx.setStrokeColor(NSColor(white: 0.98, alpha: 1.0).cgColor)
    ctx.setLineWidth(strokeWidth)
    ctx.strokePath()
    ctx.restoreGState()

    // 3. The Top Fold Flap:
    // A flap that folds down from the top arc (like a dog-ear or collar fold)
    let leftAngle = CGFloat(125.0 * .pi / 180.0)
    let rightAngle = CGFloat(55.0 * .pi / 180.0)
    let leftPt = CGPoint(x: center.x + r * cos(leftAngle), y: center.y + r * sin(leftAngle))
    let rightPt = CGPoint(x: center.x + r * cos(rightAngle), y: center.y + r * sin(rightAngle))

    // Crease line between leftPt and rightPt
    let crease = CGMutablePath()
    crease.move(to: leftPt)
    crease.addLine(to: rightPt)

    // Folded arc curving down inside
    let foldApex = CGPoint(x: center.x, y: center.y + r * 0.38)
    let foldFlap = CGMutablePath()
    foldFlap.move(to: leftPt)
    foldFlap.addQuadCurve(to: rightPt, control: foldApex)

    // Drop shadow cast by the folded flap onto the circle interior
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 16.0, color: NSColor.black.withAlphaComponent(0.85).cgColor)
    ctx.addPath(foldFlap)
    ctx.setStrokeColor(NSColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1.0).cgColor)
    ctx.setLineWidth(strokeWidth + 6)
    ctx.strokePath()
    ctx.restoreGState()

    // Fold flap glow
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 24.0, color: NSColor.white.withAlphaComponent(0.60).cgColor)
    ctx.addPath(foldFlap)
    ctx.setStrokeColor(NSColor.white.cgColor)
    ctx.setLineWidth(strokeWidth)
    ctx.setLineCap(.round)
    ctx.strokePath()
    ctx.restoreGState()

    // Fold flap sharp core
    ctx.saveGState()
    ctx.addPath(foldFlap)
    ctx.setStrokeColor(NSColor(white: 1.0, alpha: 1.0).cgColor)
    ctx.setLineWidth(strokeWidth)
    ctx.setLineCap(.round)
    ctx.strokePath()
    ctx.restoreGState()

    // Subtle dashed crease line
    ctx.saveGState()
    ctx.addPath(crease)
    ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.35).cgColor)
    ctx.setLineWidth(2.5)
    ctx.setLineDash(phase: 0, lengths: [6, 5])
    ctx.strokePath()
    ctx.restoreGState()

    ctx.restoreGState() // squircle clip
    image.unlockFocus()
    return image
}

let img = renderFlapFoldedCircle()
if let tiff = img.tiffRepresentation,
   let rep = NSBitmapImageRep(data: tiff),
   let data = rep.representation(using: .png, properties: [:]) {
    try! data.write(to: URL(fileURLWithPath: "assets/folded_circle_flap.png"))
    print("Saved to assets/folded_circle_flap.png")
}
