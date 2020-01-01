//
//  File.swift
//  
//
//  Created by Rob Napier on 1/1/20.
//

import Foundation
import CoreText

private extension Sequence {
    func mapUntilNil<ElementOfResult>(_ transform: (Self.Element) throws -> ElementOfResult?) rethrows -> [ElementOfResult] {
        try map(transform)
            .prefix(while: { $0 != nil })
            .compactMap {$0}
    }
}

struct GlyphLocation {
    var glyphRange: CFRange
    var anchor: CGFloat // Center location
}

struct GlyphRun {
    var run: CTRun
    var locations: [GlyphLocation]
    var tangents: [PathTangent] = []

    mutating func updatePositions(withTangents tangentGenerator: inout TangentGenerator) {
        tangents = locations.mapUntilNil { tangentGenerator.getTangent(at: $0.anchor) }
    }

    func draw(in context: CGContext) {
        let baseTextMatrix = context.textMatrix
        defer { context.textMatrix = baseTextMatrix }

        for (location, tangent) in zip(locations, tangents) {
            context.saveGState()
            defer { context.restoreGState() }

            let tangentPoint = tangent.point
            let angle = tangent.angle

            // FIXME: Apply other attributes

            context.translateBy(x: tangentPoint.x, y: tangentPoint.y)
            context.rotate(by: angle)

            context.textMatrix = baseTextMatrix.translatedBy(x: -location.anchor, y: 0)

            CTRunDraw(run, context, location.glyphRange)
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

            let anchors = zip(positions, widths).map { $0.x + $1 / 2 }

            let locations = anchors.enumerated()
                .map { GlyphLocation(glyphRange: CFRange(location: $0, length: 1), anchor: $1) }
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
        context.textMatrix = CGAffineTransform(translationX: 0, y:0).scaledBy(x: 1, y: -1)

        for run in glyphRuns {
            run.draw(in: context)
        }
    }
}
