//
//  PathText.swift
//  CurvyText
//
//  Created by Rob Napier on 12/6/19.
//  Copyright © 2019 Rob Napier. All rights reserved.
//

import SwiftUI

// Terminology:
//     t: Value from 0 to 1, where 0 is the starting point, and 1 is the final point.
//        Note that t=0.5 does *not* mean "half-way through the curve."
//
//     linearDistance: 1-D distance along the path
//
//     location: a linearDistance from the starting point
//
//     distance: 2-D Eucledian distance

@available(iOS 13.0, *)
public struct PathText: UIViewRepresentable {
    public var text: NSAttributedString
    public var path: Path

    public init(text: NSAttributedString, path: Path) {
        self.text = text
        self.path = path
    }

    public func makeUIView(context: UIViewRepresentableContext<PathText>) -> PathTextView {
        PathTextView()
    }

    public func updateUIView(_ uiView: PathTextView, context: UIViewRepresentableContext<PathText>) {
        uiView.text = text
        uiView.path = path
    }
}

/*
 Draws attributed text along a cubic Bezier path defined by P0, P1, P2, and P3
 */
@available(iOS 13.0, *)
public class PathTextView: UIView {

    public var path = Path() {
        didSet {
            setNeedsDisplay()
        }
    }

    public var text: NSAttributedString {
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

    public init() {
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        super.init(frame: .zero)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func draw(_ rect: CGRect) {

        let tangents = path.tangents(atLocations: locations.map { $0.x })

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
}

@available(iOS 13.0.0, *)
struct PathText_Previews: PreviewProvider {
    static let text: NSAttributedString = {
        let string = NSString("You can display text along a curve, with bold, color, and big text.")

        let s = NSMutableAttributedString(string: string as String,
                                          attributes: [.font: UIFont.systemFont(ofSize: 16)])

        s.addAttributes([.font: UIFont.boldSystemFont(ofSize: 16)], range: string.range(of: "bold"))
        s.addAttributes([.foregroundColor: UIColor.red], range: string.range(of: "color"))
        s.addAttributes([.font: UIFont.systemFont(ofSize: 32)], range: string.range(of: "big text"))
        return s
    }()

    static func CurveView() -> some View {
        let P0 = CGPoint(x: 50, y: 500)
        let P1 = CGPoint(x: 300, y: 300)
        let P2 = CGPoint(x: 400, y: 700)
        let P3 = CGPoint(x: 650, y: 500)

        let path = Path() {
            $0.move(to: P0)
            $0.addCurve(to: P3, control1: P1, control2: P2)
        }

        return PathText(text: text, path: path)
    }

    static func LineView() -> some View {
        let P0 = CGPoint(x: 50, y: 500)
        let P1 = CGPoint(x: 650, y: 500)

        let path = Path() {
            $0.move(to: P0)
            $0.addLine(to: P1)
        }

        return PathText(text: text, path: path)
    }

    static func LinesView() -> some View {
        let P0 = CGPoint(x: 50, y: 500)
        let P1 = CGPoint(x: 150, y: 200)
        let P2 = CGPoint(x: 650, y: 500)

        let path = Path() {
            $0.move(to: P0)
            $0.addLine(to: P1)
            $0.addLine(to: P2)
        }

        return ZStack {
            PathText(text: text, path: path)
            path.stroke(Color.blue, lineWidth: 2)
        }
    }


    static func LineAndCurveView() -> some View {
        let P0 = CGPoint(x: 50, y: 500)
        let P1 = CGPoint(x: 150, y: 300)
        let C1 = CGPoint(x: 300, y: 200)
        let C2 = CGPoint(x: 300, y: 500)
        let P3 = CGPoint(x: 650, y: 500)

        let path = Path() {
            $0.move(to: P0)
            $0.addLine(to: P1)
            $0.addCurve(to: P3, control1: C1, control2: C2)

        }

        return ZStack {
            PathText(text: text, path: path)
            path.stroke(Color.blue, lineWidth: 2)
        }
    }
    static var previews: some View {
        Group {
            CurveView()
            LineView()
            LinesView()
            LineAndCurveView()
        }
    }
}

protocol PathSection {
    var start: CGPoint { get }
    var end: CGPoint { get }
    func getTangent(t: CGFloat) -> PathTangent
    func nextTangent(linearDistance: CGFloat, after: PathTangent) -> NextTangent
}

extension PathSection {
    // Default impl
    func nextTangent(linearDistance: CGFloat, after lastTangent: PathTangent) -> NextTangent {
        // Simplistic routine to find the t along Bezier that is
        // a linear distance away from a previous tangent.
        // This routine just walks forward, accumulating Euclidean approximations until it finds
        // a point at least linearDistance away. Good optimizations here would reduce the number
        // of guesses, but this is tricky since if we go too far out, the
        // curve might loop back on leading to incorrect results. Tuning
        // kStep is good start.
        //        func getOffset(atDistance distance: CGFloat, from point: CGPoint, offset: CGFloat) -> CGFloat {
        let point = lastTangent.point

        let step: CGFloat = 0.001 // 0.0001 - 0.001 work well
        var approximateLinearDistance: CGFloat = 0
        var tangent = lastTangent
        while approximateLinearDistance <= linearDistance && tangent.t < 1.0 {
            tangent = getTangent(t: tangent.t + step)
            approximateLinearDistance = point.distance(to: tangent.point) // FIXME: Inefficient?
        }

        if tangent.t >= 1.0 {
            return .insufficient(remainingLinearDistance: approximateLinearDistance)
        } else {
            return .found(tangent)
        }
    }
}

struct PathTangent: Equatable {
    var t: CGFloat
    var point: CGPoint
    var angle: CGFloat
}

enum NextTangent {
    case found(PathTangent)
    case insufficient(remainingLinearDistance: CGFloat)
}

@available(iOS 13.0, *)
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

    // Locations must be in ascending order
    func tangents(atLocations locations: [CGFloat]) -> [PathTangent] {
        assert(locations == locations.sorted())

        var tangents: [PathTangent] = []

        var sections = self.sections()[...]
        var locations = locations[...]

        var lastLocation: CGFloat = 0.0
        var lastTangent: PathTangent?

        while let location = locations.first, let section = sections.first  {
            let currentTangent = lastTangent ?? section.getTangent(t: 0)

            guard location != lastLocation else {
                tangents.append(currentTangent)
                locations = locations.dropFirst()
                continue
            }

            let linearDistance = location - lastLocation

            switch section.nextTangent(linearDistance: linearDistance,
                                       after: currentTangent) {
            case .found(let tangent):
                tangents.append(tangent)
                lastTangent = tangent
                lastLocation = location
                locations = locations.dropFirst()

            case .insufficient(remainingLinearDistance: _):
                lastTangent = nil
                lastLocation = location
                sections = sections.dropFirst()
            }
        }

        return tangents
    }
}

struct PathLineSection: PathSection {
    let start, end: CGPoint

    func getTangent(t: CGFloat) -> PathTangent {
        let dx = end.x - start.x
        let dy = end.y - start.y
        
        let x = start.x + dx * t
        let y = start.y + dy * t

        return PathTangent(t: t,
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

    func getTangent(t: CGFloat) -> PathTangent {
        let dx = bezierPrime(t, p0.x, p1.x, p2.x, p3.x)
        let dy = bezierPrime(t, p0.y, p1.y, p2.y, p3.y)

        let x = bezier(t, p0.x, p1.x, p2.x, p3.x)
        let y = bezier(t, p0.y, p1.y, p2.y, p3.y)

        return PathTangent(t: t,
                           point: CGPoint(x: x, y: y),
                           angle: atan2(dy, dx))
    }
}
