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

// --------------------------------------------------------------------
// VARIANT A: Symmetrical Top Fold (Refined & Pure)
// The circle sweeps around the bottom, and at the top it folds inward
// --------------------------------------------------------------------
func renderVariantA() -> NSImage {
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

    // Angles in radians (0 is right, pi/2 is top, pi is left, 3pi/2 is bottom)
    // We want the main circle to go from angle 50° counter-clockwise around bottom to 130°
    // 50° = 50 * pi / 180, 130° = 130 * pi / 180
    let rightAngle = CGFloat(52.0 * .pi / 180.0)
    let leftAngle = CGFloat(128.0 * .pi / 180.0)

    let leftPt = CGPoint(x: center.x + r * cos(leftAngle), y: center.y + r * sin(leftAngle))
    let rightPt = CGPoint(x: center.x + r * cos(rightAngle), y: center.y + r * sin(rightAngle))

    // Main Circle Arc (clockwise in CG context = sweeping down through 270 deg)
    let mainArc = CGMutablePath()
    mainArc.addArc(center: center, radius: r, startAngle: leftAngle, endAngle: rightAngle, clockwise: true)

    // The Folded Flap at top:
    // It connects leftPt to rightPt, curving downward into the circle
    let foldApex = CGPoint(x: center.x, y: center.y + r * 0.46)
    let foldPath = CGMutablePath()
    foldPath.move(to: leftPt)
    foldPath.addQuadCurve(to: rightPt, control: foldApex)

    // Crease line across (subtle dashed / light line)
    let creasePath = CGMutablePath()
    creasePath.move(to: leftPt)
    creasePath.addLine(to: rightPt)

    // A. Outer Glow for Main Arc
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 28.0, color: NSColor.white.withAlphaComponent(0.50).cgColor)
    ctx.addPath(mainArc)
    ctx.setStrokeColor(NSColor.white.cgColor)
    ctx.setLineWidth(strokeWidth)
    ctx.strokePath()
    ctx.restoreGState()

    // B. Sharp Main Arc
    ctx.saveGState()
    ctx.addPath(mainArc)
    ctx.setStrokeColor(NSColor(white: 0.98, alpha: 1.0).cgColor)
    ctx.setLineWidth(strokeWidth)
    ctx.strokePath()
    ctx.restoreGState()

    // C. Shadow under Folded Flap
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 16.0, color: NSColor.black.withAlphaComponent(0.80).cgColor)
    ctx.addPath(foldPath)
    ctx.setStrokeColor(NSColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1.0).cgColor)
    ctx.setLineWidth(strokeWidth + 6)
    ctx.strokePath()
    ctx.restoreGState()

    // D. Glow for Folded Flap
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 26.0, color: NSColor.white.withAlphaComponent(0.60).cgColor)
    ctx.addPath(foldPath)
    ctx.setStrokeColor(NSColor.white.cgColor)
    ctx.setLineWidth(strokeWidth)
    ctx.setLineCap(.round)
    ctx.strokePath()
    ctx.restoreGState()

    // E. Sharp Folded Flap
    ctx.saveGState()
    ctx.addPath(foldPath)
    ctx.setStrokeColor(NSColor(white: 1.0, alpha: 1.0).cgColor)
    ctx.setLineWidth(strokeWidth)
    ctx.setLineCap(.round)
    ctx.strokePath()
    ctx.restoreGState()

    // F. Crease accent
    ctx.saveGState()
    ctx.addPath(creasePath)
    ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.28).cgColor)
    ctx.setLineWidth(3.0)
    ctx.setLineDash(phase: 0, lengths: [6, 6])
    ctx.strokePath()
    ctx.restoreGState()

    ctx.restoreGState() // squircle clip
    image.unlockFocus()
    return image
}

// --------------------------------------------------------------------
// VARIANT B: Elegant Asymmetric / Diagonal Dog-Ear Fold (Top-Right)
// The circle has its top-right edge folded down over itself
// --------------------------------------------------------------------
func renderVariantB() -> NSImage {
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

    // Fold is between 25° (right) and 95° (top)
    let angleRight = CGFloat(20.0 * .pi / 180.0)
    let angleTop = CGFloat(95.0 * .pi / 180.0)

    let pRight = CGPoint(x: center.x + r * cos(angleRight), y: center.y + r * sin(angleRight))
    let pTop = CGPoint(x: center.x + r * cos(angleTop), y: center.y + r * sin(angleTop))

    // Main Circle Arc (sweeps clockwise from 95° through bottom to 20°)
    let mainArc = CGMutablePath()
    mainArc.addArc(center: center, radius: r, startAngle: angleTop, endAngle: angleRight, clockwise: true)

    // Folded corner flap:
    // Crease line connects pTop and pRight
    // The top-right arc folded inward:
    let flapCorner = CGPoint(x: center.x + r * 0.40, y: center.y + r * 0.40)
    let foldFlap = CGMutablePath()
    foldFlap.move(to: pTop)
    foldFlap.addLine(to: flapCorner)
    foldFlap.addLine(to: pRight)

    let crease = CGMutablePath()
    crease.move(to: pTop)
    crease.addLine(to: pRight)

    // A. Main Arc Glow & Stroke
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 28.0, color: NSColor.white.withAlphaComponent(0.50).cgColor)
    ctx.addPath(mainArc)
    ctx.setStrokeColor(NSColor.white.cgColor)
    ctx.setLineWidth(strokeWidth)
    ctx.strokePath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(mainArc)
    ctx.setStrokeColor(NSColor(white: 0.98, alpha: 1.0).cgColor)
    ctx.setLineWidth(strokeWidth)
    ctx.strokePath()
    ctx.restoreGState()

    // B. Shadow under folded corner
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: -8, height: -8), blur: 16.0, color: NSColor.black.withAlphaComponent(0.75).cgColor)
    ctx.addPath(foldFlap)
    ctx.setStrokeColor(NSColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1.0).cgColor)
    ctx.setLineWidth(strokeWidth + 4)
    ctx.strokePath()
    ctx.restoreGState()

    // C. Fold Flap Glow & Stroke
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 26.0, color: NSColor.white.withAlphaComponent(0.60).cgColor)
    ctx.addPath(foldFlap)
    ctx.setStrokeColor(NSColor.white.cgColor)
    ctx.setLineWidth(strokeWidth)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.strokePath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(foldFlap)
    ctx.setStrokeColor(NSColor(white: 1.0, alpha: 1.0).cgColor)
    ctx.setLineWidth(strokeWidth)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.strokePath()
    ctx.restoreGState()

    // D. Crease line
    ctx.saveGState()
    ctx.addPath(crease)
    ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.30).cgColor)
    ctx.setLineWidth(3.0)
    ctx.setLineDash(phase: 0, lengths: [6, 6])
    ctx.strokePath()
    ctx.restoreGState()

    ctx.restoreGState() // squircle clip
    image.unlockFocus()
    return image
}

// --------------------------------------------------------------------
// VARIANT C: Continuous Circular Clip Spiral Fold
// The circle flows in a spiral: outer circle loops and folds into an inner circle
// --------------------------------------------------------------------
func renderVariantC() -> NSImage {
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

    // Outer Circle (Full circle with soft opening at top-left 110°)
    let circleRect = CGRect(x: center.x - r, y: center.y - r, width: r * 2.0, height: r * 2.0)
    let circlePath = CGPath(ellipseIn: circleRect, transform: nil)

    // Inner concentric folded loop (radius r * 0.55):
    let innerR = r * 0.52
    let innerCenter = CGPoint(x: center.x, y: center.y + (r - innerR) * 0.5)
    let innerCircleRect = CGRect(x: innerCenter.x - innerR, y: innerCenter.y - innerR, width: innerR * 2.0, height: innerR * 2.0)
    let innerPath = CGPath(ellipseIn: innerCircleRect, transform: nil)

    // Draw Outer Circle Glow & Stroke
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 28.0, color: NSColor.white.withAlphaComponent(0.48).cgColor)
    ctx.addPath(circlePath)
    ctx.setStrokeColor(NSColor.white.cgColor)
    ctx.setLineWidth(strokeWidth)
    ctx.strokePath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(circlePath)
    ctx.setStrokeColor(NSColor(white: 0.98, alpha: 1.0).cgColor)
    ctx.setLineWidth(strokeWidth)
    ctx.strokePath()
    ctx.restoreGState()

    // Draw Inner Fold Loop Glow & Stroke (intersecting at top)
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 22.0, color: NSColor.white.withAlphaComponent(0.55).cgColor)
    ctx.addPath(innerPath)
    ctx.setStrokeColor(NSColor.white.cgColor)
    ctx.setLineWidth(strokeWidth)
    ctx.strokePath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(innerPath)
    ctx.setStrokeColor(NSColor(white: 1.0, alpha: 1.0).cgColor)
    ctx.setLineWidth(strokeWidth)
    ctx.strokePath()
    ctx.restoreGState()

    ctx.restoreGState() // squircle clip
    image.unlockFocus()
    return image
}

func savePNG(image: NSImage, path: String) {
    if let tiff = image.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let data = rep.representation(using: .png, properties: [:]) {
        try! data.write(to: URL(fileURLWithPath: path))
        print("Saved to \(path)")
    }
}

savePNG(image: renderVariantA(), path: "assets/variant_a.png")
savePNG(image: renderVariantB(), path: "assets/variant_b.png")
savePNG(image: renderVariantC(), path: "assets/variant_c.png")
