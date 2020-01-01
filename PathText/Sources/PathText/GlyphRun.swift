//
//  File.swift
//  
//
//  Created by Rob Napier on 1/1/20.
//

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
