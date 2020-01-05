//
//  File.swift
//  
//
//  Created by Rob Napier on 1/1/20.
//

import Foundation
import CoreText

// For NSShaddow
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// Terminology:
//     t: Value from 0 to 1, where 0 is the starting point, and 1 is the final point.
//        Note that t=0.5 does *not* mean "half-way through the curve."
//
//     linearDistance: 1-D distance along the path
//
//     location: a linearDistance from the starting point
//
//     distance: 2-D Eucledian distance

private extension Sequence {
    func mapUntilNil<ElementOfResult>(_ transform: (Self.Element) throws -> ElementOfResult?) rethrows -> [ElementOfResult] {
        try map(transform)
            .prefix(while: { $0 != nil })
            .compactMap {$0}
    }
}

struct TypographicBounds {
    var width: CGFloat
    var ascent: CGFloat
    var descent: CGFloat
    var height: CGFloat { ascent + descent }
    var rect: CGRect {
        CGRect(origin: CGPoint(x: 0, y: ascent), size: CGSize(width: width, height: height))
    }
}

extension TypographicBounds {
    init(run: CTRun, index: Int) {
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        let width = CGFloat(CTRunGetTypographicBounds(run,
                                                      CFRange(location: index, length: 1),
                                                      &ascent, &descent, nil))
        self.init(width: width, ascent: ascent, descent: descent)
    }
}

struct GlyphLocation {
    var glyph: CGGlyph
    var position: CGPoint
    var typographicBounds: TypographicBounds
    var width: CGFloat { typographicBounds.width }
    var anchor: CGFloat { position.x + width / 2 }
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
    var run: CTRun
    var locations: [GlyphLocation]
    var tangents: [PathTangent] = []

    mutating func updatePositions(withTangents tangentGenerator: inout TangentGenerator) {
        tangents = locations.mapUntilNil { tangentGenerator.getTangent(at: $0.anchor) }
    }

    var typographicBounds: CGRect {
        // FIXME: Duplicate
        let attributes = CTRunGetAttributes(run) as! [NSAttributedString.Key : Any]
        let baselineOffset = attributes[.baselineOffset] as? CGFloat ?? 0

        let transformed: [CGRect] = zip(locations, tangents).map { (arg) in
            let (location, tangent) = arg

            let tangentPoint = tangent.point
            let angle = tangent.angle

            return location.typographicBounds.rect
                .offsetBy(dx: 0, dy:  -2 * location.typographicBounds.ascent)   // Normalize to baseline
                .offsetBy(dx: -location.width / 2, dy: -(location.position.y + baselineOffset)) // Move anchor to .zero
                .applying(.init(rotationAngle: angle))  // Rotate
                .offsetBy(dx: tangentPoint.x, dy: tangentPoint.y)   // Translate in rotated context
        }

        return transformed.reduce(.null) { $0.union($1) }
    }

    func draw(in context: CGContext) {
        context.saveGState()
        defer { context.restoreGState() }

        let attributes = CTRunGetAttributes(run) as! [NSAttributedString.Key : Any]
        let baselineOffset = attributes[.baselineOffset] as? CGFloat ?? 0

        context.apply(attributes: attributes)

        for (location, tangent) in zip(locations, tangents) {
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
