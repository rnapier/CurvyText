//
//  LayoutManager.swift
//  
//
//  Created by Rob Napier on 1/5/20.
//

import Foundation
import CoreGraphics
import CoreText

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
