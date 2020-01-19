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

    public var typographicBounds: CGRect {
        // FIXME: ensureLayout? Maybe pre-calculate this?
        glyphRuns.reduce(.null) { $0.union($1.typographicBounds) }
    }

    mutating func ensureGlyphs() {
        if needsGlyphGeneration { updateGlyphs() }
    }

    mutating func ensureLayout() {
        if needsLayout { updateLayout() }
    }

    private var needsGlyphGeneration = false
    public mutating func invalidateGlyphs() { needsGlyphGeneration = true }

    private var needsLayout = false
    public mutating func invalidateLayout() { needsLayout = true }

    private var glyphRuns: [GlyphRun] = []

    private mutating func updateGlyphs() {
        let line = CTLineCreateWithAttributedString(text)
        let runs = CTLineGetGlyphRuns(line) as! [CTRun]

        glyphRuns = runs.map { run in
            let glyphCount = CTRunGetGlyphCount(run)

            let positions: [CGPoint] = Array(unsafeUninitializedCapacity: glyphCount) { (buffer, initialized) in
                CTRunGetPositions(run, CFRange(), buffer.baseAddress!)
                initialized = glyphCount
            }

            let glyphs = Array<CGGlyph>(unsafeUninitializedCapacity: glyphCount) { (buffer, initialized) in
                CTRunGetGlyphs(run, CFRange(), buffer.baseAddress!)
                initialized = glyphCount
            }

            let locations: [GlyphBoxes] = (0..<glyphCount).map { i in
                GlyphBoxes(run: run, index: i, glyph: glyphs[i], position: positions[i])
            }
            .sorted { $0.anchor < $1.anchor }

            return GlyphRun(run: run, boxes: locations)
        }

        needsGlyphGeneration = false
    }

    private mutating func updateLayout() {
        ensureGlyphs()
        var tangents = TangentGenerator(path: path)
        glyphRuns = glyphRuns.map {
            var glyphRun = $0
            glyphRun.updateTangets(with: &tangents)
            return glyphRun
        }

        needsLayout = false
    }

    public mutating func draw(in context: CGContext) {
        ensureLayout()

        for run in glyphRuns {
            run.draw(in: context)
        }
    }
}
