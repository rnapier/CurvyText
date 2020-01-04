//
//  File.swift
//  
//
//  Created by Rob Napier on 1/1/20.
//

import Foundation
import CoreText

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

struct GlyphLocation {
    var glyph: CGGlyph
    var position: CGPoint
    var width: CGFloat
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

            context.translateBy(x: tangentPoint.x, y: tangentPoint.y)
            context.rotate(by: angle)

            context.textPosition = CGPoint(x: -location.width / 2, y: -location.position.y - baselineOffset)

            // Use CGContext rather than CTFontDrawGlyphs to get context features like shadow
            context.showGlyphs([location.glyph], at: [.zero])
        }
    }
}

struct PathTextLayoutManager {
    public var text: NSAttributedString = NSAttributedString() {
        didSet {
            invalidateGlyphs()
        }
    }

    public var path: CGPath = CGMutablePath() {
        didSet {
            invalidateLayout()
        }
    }

    private var needsGlyphGeneration = false
    public mutating func invalidateGlyphs() { needsGlyphGeneration = true }

    private var needsLayout = false
    public mutating func invalidateLayout() { needsLayout = true }

    private var glyphRuns: [GlyphRun] = []

    private mutating func updateGlyphRuns() {
        let line = CTLineCreateWithAttributedString(text)
        let runs = CTLineGetGlyphRuns(line) as! [CTRun]

        glyphRuns = runs.map { run in
            let glyphCount = CTRunGetGlyphCount(run)

            let positions: [CGPoint] = Array(unsafeUninitializedCapacity: glyphCount) { (buffer, initialized) in
                CTRunGetPositions(run, CFRange(), buffer.baseAddress!)
                initialized = glyphCount
            }

            let widths: [CGFloat] = (0..<glyphCount).map {
                CGFloat(CTRunGetTypographicBounds(run, CFRange(location: $0, length: 1), nil, nil, nil))
            }

            let glyphs = Array<CGGlyph>(unsafeUninitializedCapacity: glyphCount) { (buffer, initialized) in
                CTRunGetGlyphs(run, CFRange(), buffer.baseAddress!)
                initialized = glyphCount
            }

            let locations = zip(glyphs, zip(positions, widths))
                .map { GlyphLocation(glyph: $0, position: $1.0, width: $1.1) }
                .sorted { $0.anchor < $1.anchor }

            return GlyphRun(run: run, locations: locations)
        }

        needsGlyphGeneration = false
    }

    private mutating func updateGlyphPositions() {
        if needsGlyphGeneration { updateGlyphRuns() }
        var tangents = TangentGenerator(path: path)
        glyphRuns = glyphRuns.map {
            var glyphRun = $0
            glyphRun.updatePositions(withTangents: &tangents)
            return glyphRun
        }

        needsLayout = false
    }

    public mutating func draw(in context: CGContext) {
        if needsLayout {
            updateGlyphPositions()
        }

        // FIXME: Check if flip is needed (macos)
        context.textMatrix = CGAffineTransform(scaleX: 1, y: -1)

        for run in glyphRuns {
            run.draw(in: context)
        }
    }
}
