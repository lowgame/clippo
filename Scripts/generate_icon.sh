#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR"

echo "=== Clippo Ultra-Glowish Folded Circle İkonu Üretiliyor ==="

swift - << 'SWIFT'
import AppKit
import CoreGraphics

let size: CGFloat = 1024
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(size),
    pixelsHigh: Int(size),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!

NSGraphicsContext.saveGraphicsState()
let context = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = context
let cg = context.cgContext

let rect = NSRect(x: 0, y: 0, width: size, height: size)

// 1. Deep Pitch Black Background (#000000)
let bgPath = NSBezierPath(roundedRect: rect, xRadius: 228, yRadius: 228)
NSColor.black.setFill()
bgPath.fill()

// 2. Subtle 1px rim
let rimPath = NSBezierPath(roundedRect: rect.insetBy(dx: 2, dy: 2), xRadius: 226, yRadius: 226)
rimPath.lineWidth = 2.0
NSColor(white: 1.0, alpha: 0.12).setStroke()
rimPath.stroke()

let center = CGPoint(x: size / 2, y: size / 2)
let radius: CGFloat = 280

// 3. Deep Ethereal Ambient Radial Glow
let colorSpace = CGColorSpaceCreateDeviceRGB()
let glowColors = [
    NSColor(white: 1.0, alpha: 0.28).cgColor,
    NSColor(white: 1.0, alpha: 0.16).cgColor,
    NSColor(white: 1.0, alpha: 0.05).cgColor,
    NSColor(white: 0.0, alpha: 0.0).cgColor
] as CFArray
let glowLocations: [CGFloat] = [0.0, 0.35, 0.65, 1.0]
if let radialGradient = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: glowLocations) {
    cg.saveGState()
    cg.drawRadialGradient(
        radialGradient,
        startCenter: center,
        startRadius: 0.0,
        endCenter: center,
        endRadius: radius * 1.6,
        options: []
    )
    cg.restoreGState()
}

// 4. Geometry: Clean Origami Fold at Top-Right
let aTop = CGFloat(90.0 * .pi / 180.0)
let aRight = CGFloat(0.0 * .pi / 180.0)
let pTop = CGPoint(x: center.x, y: center.y + radius)
let pRight = CGPoint(x: center.x + radius, y: center.y)

// Main circle arc around bottom (from 90° counter-clockwise to 0°)
let mainArc = CGMutablePath()
mainArc.addArc(center: center, radius: radius, startAngle: aTop, endAngle: aRight, clockwise: false)

// Crease line (straight diagonal 45° fold line)
let crease = CGMutablePath()
crease.move(to: pTop)
crease.addLine(to: pRight)

// Corner folded inward toward center
let cornerTip = CGPoint(x: center.x + radius * 0.293, y: center.y + radius * 0.293)
let flap = CGMutablePath()
flap.move(to: pTop)
flap.addLine(to: cornerTip)
flap.addLine(to: pRight)

let flapPoly = CGMutablePath()
flapPoly.move(to: pTop)
flapPoly.addLine(to: cornerTip)
flapPoly.addLine(to: pRight)
flapPoly.closeSubpath()

// 5. Realistic Ambient Occlusion Drop Shadow under flap
cg.saveGState()
cg.setShadow(offset: CGSize(width: -14, height: -14), blur: 24.0, color: NSColor.black.withAlphaComponent(0.95).cgColor)
cg.addPath(flapPoly)
cg.setFillColor(NSColor(white: 0.03, alpha: 1.0).cgColor)
cg.fillPath()
cg.restoreGState()

// 6. Subtle translucent paper sheen on flap
cg.saveGState()
cg.addPath(flapPoly)
cg.setFillColor(NSColor(white: 1.0, alpha: 0.07).cgColor)
cg.fillPath()
cg.restoreGState()

// 7. Multi-tier Physical Gaussian Glow (Matching Lowgame Suite Standard)
let glowPasses: [(lineWidth: CGFloat, blur: CGFloat, alpha: CGFloat)] = [
    (32.0, 180.0, 0.25),
    (28.0, 110.0, 0.35),
    (24.0, 60.0, 0.55),
    (20.0, 28.0, 0.75),
    (16.0, 12.0, 0.90),
    (12.0, 4.0, 1.0)
]

// Glow on main arc and crease
for pass in glowPasses {
    cg.saveGState()
    cg.setLineJoin(.round)
    cg.setLineCap(.round)
    cg.setLineWidth(pass.lineWidth)
    cg.setShadow(offset: .zero, blur: pass.blur, color: NSColor(white: 1.0, alpha: pass.alpha).cgColor)
    cg.addPath(mainArc)
    cg.addPath(crease)
    cg.setStrokeColor(NSColor(white: 1.0, alpha: pass.alpha).cgColor)
    cg.strokePath()
    cg.restoreGState()
}

// Glow on flap (calibrated for top layer)
for pass in glowPasses.suffix(4) {
    cg.saveGState()
    cg.setLineJoin(.round)
    cg.setLineCap(.round)
    cg.setLineWidth(pass.lineWidth * 0.85)
    cg.setShadow(offset: .zero, blur: pass.blur * 0.65, color: NSColor(white: 1.0, alpha: pass.alpha * 0.85).cgColor)
    cg.addPath(flap)
    cg.setStrokeColor(NSColor(white: 1.0, alpha: pass.alpha * 0.85).cgColor)
    cg.strokePath()
    cg.restoreGState()
}

// 8. Crisp Brilliant White Core Filament (10pt stroke)
cg.saveGState()
cg.setLineJoin(.round)
cg.setLineCap(.round)
cg.setLineWidth(10.0)
cg.addPath(mainArc)
cg.addPath(crease)
cg.setStrokeColor(NSColor.white.cgColor)
cg.strokePath()
cg.restoreGState()

cg.saveGState()
cg.setLineJoin(.round)
cg.setLineCap(.round)
cg.setLineWidth(9.0)
cg.addPath(flap)
cg.setStrokeColor(NSColor(white: 0.98, alpha: 1.0).cgColor)
cg.strokePath()
cg.restoreGState()

NSGraphicsContext.restoreGraphicsState()

let pngData = rep.representation(using: .png, properties: [:])!
try! pngData.write(to: URL(fileURLWithPath: "Resources/AppIcon.png"))
try! pngData.write(to: URL(fileURLWithPath: "assets/app_icon_1024.png"))
SWIFT

mkdir -p build/clippo.iconset
sips -z 16 16     Resources/AppIcon.png --out build/clippo.iconset/icon_16x16.png > /dev/null
sips -z 32 32     Resources/AppIcon.png --out build/clippo.iconset/icon_16x16@2x.png > /dev/null
sips -z 32 32     Resources/AppIcon.png --out build/clippo.iconset/icon_32x32.png > /dev/null
sips -z 64 64     Resources/AppIcon.png --out build/clippo.iconset/icon_32x32@2x.png > /dev/null
sips -z 128 128   Resources/AppIcon.png --out build/clippo.iconset/icon_128x128.png > /dev/null
sips -z 256 256   Resources/AppIcon.png --out build/clippo.iconset/icon_128x128@2x.png > /dev/null
sips -z 256 256   Resources/AppIcon.png --out build/clippo.iconset/icon_256x256.png > /dev/null
sips -z 512 512   Resources/AppIcon.png --out build/clippo.iconset/icon_256x256@2x.png > /dev/null
sips -z 512 512   Resources/AppIcon.png --out build/clippo.iconset/icon_512x512.png > /dev/null
sips -z 1024 1024 Resources/AppIcon.png --out build/clippo.iconset/icon_512x512@2x.png > /dev/null

iconutil -c icns build/clippo.iconset -o Resources/AppIcon.icns
rm -rf build/clippo.iconset

echo "Tamamlandı: Resources/AppIcon.icns ve assets/app_icon_1024.png güncellendi."
