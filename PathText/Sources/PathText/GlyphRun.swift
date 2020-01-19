//
//  File.swift
//  
//
//  Created by Rob Napier on 1/1/20.
//

import Foundation
import CoreText

// For NSShadow
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

private extension Sequence {
    func mapUntilNil<ElementOfResult>(_ transform: (Self.Element) throws -> ElementOfResult?) rethrows -> [ElementOfResult] {
        try map(transform)
            .prefix(while: { $0 != nil })
            .compactMap {$0}
    }
}

// Location in text space
struct GlyphBoxes {
    var glyph: CGGlyph
    var bounds: CGRect
    var baseline: CGFloat // Distance from bottom of bounds to baseline
}

extension GlyphBoxes {
    // Location of left (leading?) baseline in text space.
    var position: CGPoint { CGPoint(x: bounds.minX, y: bounds.maxY - baseline)}
    var width: CGFloat { bounds.width }
    var anchor: CGFloat { position.x + width / 2 }  // Point on baseline to connect to tangent
    var height: CGFloat { bounds.height }
    var ascent: CGFloat { height - baseline }

    init(run: CTRun, index: CFIndex, glyph: CGGlyph, position: CGPoint) {
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        let width = CGFloat(CTRunGetTypographicBounds(run,
                                                      CFRange(location: index, length: 1),
                                                      &ascent, &descent, nil))
        self.glyph = glyph
        self.bounds = CGRect(x: position.x, y: position.y - ascent, width: width, height: ascent + descent)
        self.baseline = descent
    }
}

private func makeCGColor(_ value: Any) -> CGColor {
    if let color = value as? PlatformColor {
        return color.cgColor
    } else {
        return value as! CGColor
    }
}

private extension CGContext {
    func apply(attributes: [NSAttributedString.Key : Any]) {
        for (key, value) in attributes {
            switch key {
            case .font:
                let ctFont = value as! CTFont
                let cgFont = CTFontCopyGraphicsFont(ctFont, nil)
                self.setFont(cgFont)
                self.setFontSize(CTFontGetSize(ctFont))

            case .foregroundColor:
                self.setFillColor(makeCGColor(value))

            case .strokeColor:
                self.setStrokeColor(makeCGColor(value))

            case .strokeWidth:
                let width = value as! CGFloat

                let mode: CGTextDrawingMode
                if width < 0 {
                    mode = .fillStroke
                } else if width == 0 {
                    mode = .fill
                } else {
                    mode = .stroke
                }
                self.setTextDrawingMode(mode)
                self.setLineWidth(width)

            // Remember: NSShadow does not honor CTM. It is always in the default user coordinates.
            case .shadow:
                let shadow = value as! NSShadow
                if let color = shadow.shadowColor {
                    self.setShadow(offset: shadow.shadowOffset, blur: shadow.shadowBlurRadius, color: makeCGColor(color))
                } else {
                    self.setShadow(offset: shadow.shadowOffset, blur: shadow.shadowBlurRadius)
                }

            //
            // Ignore for various reasons
            //

            // Ignore because CTRun already handles it
            case .kern,
                 .ligature,
                 .writingDirection:
                break

            // Ingore because other methods already handle it
            case .baselineOffset:
                break

            // Ignore because they are unsupported by CoreText
            case .expansion,    // Expansion is not fully supported; it'll act more like tracking
            .link,
            .obliqueness,
            .textEffect:
                break

            // Ignore because it would look bad if implemented
            case .backgroundColor,
                 .paragraphStyle,
                 .strikethroughStyle,
                 .strikethroughColor,
                 .underlineStyle,
                 .underlineColor:
                break

            // Ignore because it's unneeded information
            case .init("NSOriginalFont"):   // Original font before substitution.
                break

            default:
                print("Unknown attribute: \(key) = \(value)")   // FIXME: Just for debugging.
            }
        }
    }
}

struct GlyphRun {
    let run: CTRun
    let boxes: [GlyphBoxes]
    let attributes: [NSAttributedString.Key : Any]

    init(run: CTRun, boxes: [GlyphBoxes]) {
        self.run = run
        self.boxes = boxes
        self.attributes = CTRunGetAttributes(run) as! [NSAttributedString.Key : Any]
    }

    private(set) var tangents: [PathTangent] = [] {
        didSet {
            updateTypographicBounds()
        }
    }

    var baselineOffset: CGFloat {
        attributes[.baselineOffset] as? CGFloat ?? 0
    }

    mutating func updateTangets(with tangentGenerator: inout TangentGenerator) {
        tangents = boxes.mapUntilNil { tangentGenerator.getTangent(at: $0.anchor) }
    }

    private mutating func updateTypographicBounds() {
        let transformed: [CGRect] = zip(boxes, tangents).map { (arg) in
            let (location, tangent) = arg

            let tangentPoint = tangent.point
            let angle = tangent.angle

            return location.bounds
                .offsetBy(dx: -location.anchor, dy: -(location.position.y + baselineOffset)) // Move anchor to .zero
                .applying(.init(rotationAngle: angle))  // Rotate
                .offsetBy(dx: tangentPoint.x, dy: tangentPoint.y)   // Translate in rotated context
        }

        typographicBounds = transformed.reduce(.null) { $0.union($1) }
    }

    var typographicBounds: CGRect = .null

    func draw(in context: CGContext) {
        // DEBUGGING
        // context.stroke(typographicBounds)

        context.saveGState()
        defer { context.restoreGState() }

        context.apply(attributes: attributes)

        for (location, tangent) in zip(boxes, tangents) {
            context.saveGState()
            defer { context.restoreGState() }

            let tangentPoint = tangent.point
            let angle = tangent.angle

            context.translateBy(x: tangentPoint.x, y: tangentPoint.y)   // y is flipped
            context.rotate(by: angle)

            context.textPosition = CGPoint(x: -location.width / 2,
                                           y: -(location.position.y + baselineOffset))  // y is flipped

            // Use CGContext rather than CTFontDrawGlyphs to get context features like shadow
            context.showGlyphs([location.glyph], at: [.zero])
        }
    }
}
