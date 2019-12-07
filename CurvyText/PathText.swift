//
//  PathText.swift
//  CurvyText
//
//  Created by Rob Napier on 12/6/19.
//  Copyright © 2019 Rob Napier. All rights reserved.
//

import SwiftUI

struct PathText: UIViewRepresentable {
    var text: NSAttributedString
    var path: Path

    func makeUIView(context: UIViewRepresentableContext<PathText>) -> PathTextView {
        PathTextView()
    }

    func updateUIView(_ uiView: PathTextView, context: UIViewRepresentableContext<PathText>) {
        uiView.text = text
        uiView.path = path
    }
}

/*
 Draws attributed text along a cubic Bezier path defined by P0, P1, P2, and P3
 */
class PathTextView: UIView {

    var path = Path() {
        didSet {
            setNeedsDisplay()
        }
    }

    var text: NSAttributedString {
        get { textStorage }
        set {
            textStorage.setAttributedString(newValue)
            locations = (0..<layoutManager.numberOfGlyphs).map { [layoutManager] glyphIndex in
                layoutManager.location(forGlyphAt: glyphIndex)
            }

            lineFragmentOrigin = layoutManager
                .lineFragmentRect(forGlyphAt: 0, effectiveRange: nil)
                .origin
        }
    }

    private let layoutManager = NSLayoutManager()
    private let textStorage = NSTextStorage()
    private let textContainer = NSTextContainer()

    private var locations: [CGPoint] = []
    private var lineFragmentOrigin = CGPoint.zero

    init() {
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        super.init(frame: .zero)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ rect: CGRect) {

        let tangents = path.tangents(at: locations.map { $0.x })

        let sections = path.sections()

        guard let pathStart = sections.first?.start else { return }

        let context = UIGraphicsGetCurrentContext()!

        for (index, (tangent, location)) in zip(tangents, locations).enumerated() {
            context.saveGState()

            let glyphPoint = tangent.point
            let angle = tangent.angle

            context.translateBy(x: glyphPoint.x, y: glyphPoint.y)
            context.rotate(by: angle)

            // The "at:" in drawGlyphs is the origin of the line fragment. We've already adjusted the
            // context, so take that back out.
            let adjustedOrigin = CGPoint(x: -(lineFragmentOrigin.x + location.x),
                                         y: -(lineFragmentOrigin.y + location.y))

            layoutManager.drawGlyphs(forGlyphRange: NSRange(location: index, length: 1),
                                     at: adjustedOrigin)

            context.restoreGState()
        }
    }
}

// The Bezier function at t
func bezier(_ t: CGFloat, _ P0: CGFloat, _ P1: CGFloat, _ P2: CGFloat, _ P3: CGFloat) -> CGFloat {
           (1-t)*(1-t)*(1-t)         * P0
     + 3 *       (1-t)*(1-t) *     t * P1
     + 3 *             (1-t) *   t*t * P2
     +                         t*t*t * P3
}

// The slope of the Bezier function at t
func bezierPrime(_ t: CGFloat, _ P0: CGFloat, _ P1: CGFloat, _ P2: CGFloat, _ P3: CGFloat) -> CGFloat {
       0
    -  3 * (1-t)*(1-t) * P0
    + (3 * (1-t)*(1-t) * P1) - (6 * t * (1-t) * P1)
    - (3 *         t*t * P2) + (6 * t * (1-t) * P2)
    +  3 * t*t * P3
}

extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        let dx = x - other.x
        let dy = y - other.y
        return hypot(dx, dy)
    }

    static func + (lhs: CGPoint, rhs: CGSize) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.width,
                       y: lhs.y + rhs.height)
    }
}

struct PathText_Previews: PreviewProvider {
    static var previews: some View {
        let P0 = CGPoint(x: 50, y: 500)
        let P1 = CGPoint(x: 300, y: 300)
        let P2 = CGPoint(x: 400, y: 700)
        let P3 = CGPoint(x: 650, y: 500)

        let path = Path() {
            $0.move(to: P0)
            $0.addCurve(to: P3, control1: P1, control2: P2)
        }

        let text: NSAttributedString = {
            let string = NSString("You can display text along a curve, with bold, color, and big text.")

            let s = NSMutableAttributedString(string: string as String,
                                              attributes: [.font: UIFont.systemFont(ofSize: 16)])

            s.addAttributes([.font: UIFont.boldSystemFont(ofSize: 16)], range: string.range(of: "bold"))
            s.addAttributes([.foregroundColor: UIColor.red], range: string.range(of: "color"))
            s.addAttributes([.font: UIFont.systemFont(ofSize: 32)], range: string.range(of: "big text"))
            return s
        }()

        return PathText(text: text, path: path)
    }
}

protocol PathSection {
    var start: CGPoint { get }
    var end: CGPoint { get }
    func tangent(atOffset offset: CGFloat) -> PathTangent
    func nextTangent(distance: CGFloat, after: PathTangent) -> NextTangent
}

extension PathSection {
    // Default impl
        func nextTangent(distance: CGFloat, after lastTangent: PathTangent) -> NextTangent {
            // Simplistic routine to find the offset along Bezier that is
            // aDistance away from aPoint. anOffset is the offset used to
            // generate aPoint, and saves us the trouble of recalculating it
            // This routine just walks forward until it finds a point at least
            // aDistance away. Good optimizations here would reduce the number
            // of guesses, but this is tricky since if we go too far out, the
            // curve might loop back on leading to incorrect results. Tuning
            // kStep is good start.
    //        func getOffset(atDistance distance: CGFloat, from point: CGPoint, offset: CGFloat) -> CGFloat {
            let point = lastTangent.point
            let offset = lastTangent.offset

                let kStep: CGFloat = 0.001 // 0.0001 - 0.001 work well
                var newDistance: CGFloat = 0
                var newOffset = offset + kStep
                while newDistance <= distance && newOffset < 1.0 {
                    newOffset += kStep
                    newDistance = point.distance(to: tangent(atOffset: newOffset).point)     // FIXME: Inefficient
                }

            if newOffset >= 1.0 {
                fatalError() // Implement
    //            return .insufficient(remaining: <#T##CGFloat#>)
            }

            return .found(tangent(atOffset: newOffset))
        }
}

struct PathTangent {
    var offset: CGFloat
    var point: CGPoint
    var angle: CGFloat
}

enum NextTangent {
    case found(PathTangent)
    case insufficient(remaining: CGFloat)
}

extension Path {
    func sections() -> [PathSection] {
        var sections: [PathSection] = []
        var start: CGPoint?
        var current: CGPoint?
        self.forEach { (element) in
            // FIXME: Filter zero-length?
            switch element {
            case .closeSubpath:
                sections.append(PathLineSection(start: current ?? .zero, end: start ?? .zero))
                current = start
                start = nil

            case .move(to: let p):
//                sections.append(PathMoveSection(to: p))
                start = start ?? p
                current = p

            case let .curve(to: p3, control1: p1, control2: p2):
                sections.append(PathCurveSection(p0: current ?? .zero, p1: p1, p2: p2, p3: p3))
                start = start ?? .zero
                current = p3

            case .line(to: let p):
                sections.append(PathLineSection(start: current ?? .zero, end: p))
                start = start ?? .zero
                current = p

            case let .quadCurve(to: p2, control: p1):
                fatalError()
//                sections.append(PathQuadCurveSection(p0: current ?? .zero, p1: p1, p2: p2))
//                start = start ?? .zero
//                current = p2
            }
        }
        return sections
    }

    func tangents(at offsets: [CGFloat]) -> [PathTangent] {
        var sections = self.sections().reversed()

        guard let currentSection = sections.last else { return [] }

        var tangents: [PathTangent] = []

        var lastTangent = currentSection.tangent(atOffset: 0)
        var lastLocation: CGFloat = 0.0

        // Compute location for each glyph, transform the context, and then draw
        for location in offsets {
            let distance = location - lastLocation

            switch currentSection.nextTangent(distance: distance, after: lastTangent) {
            case .found(let tangent):
                tangents.append(tangent)
                lastTangent = tangent
                lastLocation = location


            case .insufficient(remaining: let remaining):
                fatalError()    // Implement
            }
        }
        return tangents
    }
}

struct PathLineSection: PathSection {
    let start, end: CGPoint

    func tangent(atOffset offset: CGFloat) -> PathTangent {
        let dx = end.x - start.x
        let dy = end.y - start.y
        
        let x = start.x + dx * offset
        let y = start.y + dy * offset

        return PathTangent(offset: offset,
                           point: CGPoint(x: x, y: y),
                           angle: atan2(dy, dx))
    }



}

//struct PathQuadCurveSection: PathSection {
//    let p0, p1, p2: CGPoint
//    var start: CGPoint { p0 }
//    var end: CGPoint { p2 }
//}

struct PathCurveSection: PathSection {

    let p0, p1, p2, p3: CGPoint
    var start: CGPoint { p0 }
    var end: CGPoint { p3 }

    func tangent(atOffset offset: CGFloat) -> PathTangent {
        let dx = bezierPrime(offset, p0.x, p1.x, p2.x, p3.x)
        let dy = bezierPrime(offset, p0.y, p1.y, p2.y, p3.y)

        let x = bezier(offset, p0.x, p1.x, p2.x, p3.x)
        let y = bezier(offset, p0.y, p1.y, p2.y, p3.y)

        return PathTangent(offset: offset,
                           point: CGPoint(x: x, y: y),
                           angle: atan2(dy, dx))
    }
}
