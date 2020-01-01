//
//  PathText.swift
//  CurvyText
//
//  Created by Rob Napier on 12/6/19.
//  Copyright © 2019 Rob Napier. All rights reserved.
//

#if canImport(SwiftUI)
import SwiftUI
#endif

#if canImport(UIKit)
import UIKit
typealias PlatformFont = UIFont
typealias PlatformColor = UIColor
#elseif canImport(AppKit)
typealias PlatformFont = NSFont
typealias PlatformColor = NSColor
#else
#error("Unsupported platform")
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

@available(iOS 13.0, *)
public struct PathText: UIViewRepresentable {
    public var text: NSAttributedString
    public var path: CGPath

    public init(text: NSAttributedString, path: Path) {
        self.init(text: text, path: path.cgPath)
    }

    public init(text: NSAttributedString, path: CGPath) {
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
public class PathTextView: UIView {

    public var text: NSAttributedString = NSAttributedString() {
        didSet {
            updateGlyphRuns()
        }
    }

    public var path: CGPath = CGMutablePath() {
        didSet {
            updateGlyphPositions()
        }
    }

    private struct GlyphLocation {
        var glyphRange: CFRange
        var anchor: CGFloat // Center location
    }

    private struct GlyphRun {
        var run: CTRun
        var locations: [GlyphLocation]
        var tangents: [PathTangent] = []

        mutating func updatePositions(withTangents tangentGenerator: inout TangentGenerator) {
            self.tangents = locations.compactMap { tangentGenerator.getTangent(at: $0.anchor) }
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

    private var glyphRuns: [GlyphRun] = []

    private func updateGlyphRuns() {
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

        updateGlyphPositions()
    }

    private func updateGlyphPositions() {
        var tangents = TangentGenerator(path: path)
        glyphRuns = glyphRuns.map {
            var glyphRun = $0
            glyphRun.updatePositions(withTangents: &tangents)
            return glyphRun
        }
        setNeedsDisplay()
    }

    public init() {
        super.init(frame: .zero)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!

        // FIXME: Check if flip is needed (macos)
        context.textMatrix = CGAffineTransform(translationX: 0, y:0).scaledBy(x: 1, y: -1)

        for run in glyphRuns {
            run.draw(in: context)
        }
    }
}

@available(iOS 13.0.0, *)
struct PathText_Previews: PreviewProvider {
//    static let text: NSAttributedString = {
//        let string = NSString("You can display text along a curve, with bold, color, and big text.")
//
//        let s = NSMutableAttributedString(string: string as String,
//                                          attributes: [.font: UIFont.systemFont(ofSize: 16)])
//
//        s.addAttributes([.font: UIFont.boldSystemFont(ofSize: 16)], range: string.range(of: "bold"))
//        s.addAttributes([.foregroundColor: UIColor.red], range: string.range(of: "color"))
//        s.addAttributes([.font: UIFont.systemFont(ofSize: 32)], range: string.range(of: "big text"))
//        return s
//    }()

    static let text: NSAttributedString = {
        let string = NSString("mmii can d\u{030a}isplay العربية tëxt along a cu\u{0327}rve, with bold, color, and big text.")

        let s = NSMutableAttributedString(string: string as String,
                                          attributes: [.font: UIFont.systemFont(ofSize: 48)])

        s.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 48), range: string.range(of: "tëxt"))
        s.addAttribute(.foregroundColor, value: UIColor.red, range: string.range(of: "d\u{030a}isplay"))
        s.addAttribute(.font, value: UIFont.systemFont(ofSize: 32), range: string.range(of: "big text"))
        s.addAttribute(.baselineOffset, value: 20, range: string.range(of: "along"))

        let shadow = NSShadow()
        shadow.shadowBlurRadius = 5
        shadow.shadowColor = UIColor.green
        shadow.shadowOffset = CGSize(width: 5, height: 10)
        s.addAttribute(.shadow, value: shadow, range: string.range(of: "can"))

        s.addAttribute(.writingDirection, value: [3], range: string.range(of: "mmii"))

        return s
    }()

    static func CurveView() -> some View {
        let P0 = CGPoint(x: 50, y: 300)
        let P1 = CGPoint(x: 300, y: 100)
        let P2 = CGPoint(x: 400, y: 500)
        let P3 = CGPoint(x: 650, y: 300)

        let path = Path() {
            $0.move(to: P0)
            $0.addCurve(to: P3, control1: P1, control2: P2)
        }

        return ZStack {
            PathText(text: text, path: path)
            path.stroke(Color.blue, lineWidth: 2)
        }
    }

    static func LineView() -> some View {
        let P0 = CGPoint(x: 50, y: 300)
        let P1 = CGPoint(x: 650, y: 300)

        let path = Path() {
            $0.move(to: P0)
            $0.addLine(to: P1)
        }

        return VStack {
            Text(verbatim: text.string)
                .font(.system(size: 48))
                .padding()
                .lineLimit(1)
            ZStack {
                PathText(text: text, path: path)
                path.stroke(Color.blue, lineWidth: 2)
            }
        }
    }

    static func LinesView() -> some View {
        let P0 = CGPoint(x: 50, y: 400)
        let P1 = CGPoint(x: 150, y: 100)
        let P2 = CGPoint(x: 650, y: 400)

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
        let P0 = CGPoint(x: 50, y: 400)
        let P1 = CGPoint(x: 150, y: 200)
        let C1 = CGPoint(x: 300, y: 100)
        let C2 = CGPoint(x: 300, y: 400)
        let P3 = CGPoint(x: 650, y: 400)

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

    static func QuadCurveView() -> some View {
        let P0 = CGPoint(x: 50, y: 300)
        let P1 = CGPoint(x: 300, y: 100)
        let P2 = CGPoint(x: 650, y: 300)

        let path = Path() {
            $0.move(to: P0)
            $0.addQuadCurve(to: P2, control: P1)
        }

        return PathText(text: text, path: path)
    }

    static func RoundedRectView() -> some View {

        let P0 = CGPoint(x: 100, y: 100)
        let size = CGSize(width: 300, height: 200)
        let cornerSize = CGSize(width: 50, height: 50)

        let path = Path() {
            $0.addRoundedRect(in: CGRect(origin: P0, size: size), cornerSize: cornerSize)
        }

        return ZStack {
            PathText(text: text, path: path)
//            path.stroke(Color.blue, lineWidth: 2)
        }
    }

    static func TwoGlyphCharacter() -> some View {
        let P0 = CGPoint(x: 50, y: 300)
        let P1 = CGPoint(x: 650, y: 300)

        let path = Path() {
            $0.move(to: P0)
            $0.addLine(to: P1)
        }

        return VStack {
            Text("ÅX̊") // "X\u{030A}")
                .font(.system(size: 48))
            ZStack {
                PathText(text: NSAttributedString(string: "ÅX̊Z",
                                                  attributes: [.font: UIFont.systemFont(ofSize: 48)]), path: path)
                path.stroke(Color.blue, lineWidth: 2)
            }
        }
    }
    static var previews: some View {
        Group {
            CurveView()
            LineView()
            LinesView()
            LineAndCurveView()
            QuadCurveView()
            RoundedRectView()
            TwoGlyphCharacter()
        }.previewLayout(.fixed(width: 700, height: 500))
    }
}


//@available(iOS 13.0.0, *)
//struct PathText_Previews: PreviewProvider {
//    static let text: NSAttributedString = {
//        let string = NSString("You can display text along a curve, with bold, color, and big text.")
//
//        let s = NSMutableAttributedString(string: string as String,
//                                          attributes: [.font: UIFont.systemFont(ofSize: 16)])
//
//        s.addAttributes([.font: UIFont.boldSystemFont(ofSize: 16)], range: string.range(of: "bold"))
//        s.addAttributes([.foregroundColor: UIColor.red], range: string.range(of: "color"))
//        s.addAttributes([.font: UIFont.systemFont(ofSize: 32)], range: string.range(of: "big text"))
//        return s
//    }()
//
//    static func CurveView() -> some View {
//        let P0 = CGPoint(x: 50, y: 500)
//        let P1 = CGPoint(x: 300, y: 300)
//        let P2 = CGPoint(x: 400, y: 700)
//        let P3 = CGPoint(x: 650, y: 500)
//
//        let path = Path() {
//            $0.move(to: P0)
//            $0.addCurve(to: P3, control1: P1, control2: P2)
//        }
//
//        return PathText(text: text, path: path)
//    }
//
//    static func LineView() -> some View {
//        let P0 = CGPoint(x: 50, y: 500)
//        let P1 = CGPoint(x: 650, y: 500)
//
//        let path = Path() {
//            $0.move(to: P0)
//            $0.addLine(to: P1)
//        }
//
//        return ZStack {
//            PathText(text: text, path: path)
//            path.stroke(Color.blue, lineWidth: 2)
//        }
//    }
//
//    static func LinesView() -> some View {
//        let P0 = CGPoint(x: 50, y: 500)
//        let P1 = CGPoint(x: 150, y: 200)
//        let P2 = CGPoint(x: 650, y: 500)
//
//        let path = Path() {
//            $0.move(to: P0)
//            $0.addLine(to: P1)
//            $0.addLine(to: P2)
//        }
//
//        return ZStack {
//            PathText(text: text, path: path)
//            path.stroke(Color.blue, lineWidth: 2)
//        }
//    }
//
//    static func LineAndCurveView() -> some View {
//        let P0 = CGPoint(x: 50, y: 500)
//        let P1 = CGPoint(x: 150, y: 300)
//        let C1 = CGPoint(x: 300, y: 200)
//        let C2 = CGPoint(x: 300, y: 500)
//        let P3 = CGPoint(x: 650, y: 500)
//
//        let path = Path() {
//            $0.move(to: P0)
//            $0.addLine(to: P1)
//            $0.addCurve(to: P3, control1: C1, control2: C2)
//        }
//
//        return ZStack {
//            PathText(text: text, path: path)
//            path.stroke(Color.blue, lineWidth: 2)
//        }
//    }
//
//    static func QuadCurveView() -> some View {
//        let P0 = CGPoint(x: 50, y: 500)
//        let P1 = CGPoint(x: 300, y: 300)
//        let P2 = CGPoint(x: 650, y: 500)
//
//        let path = Path() {
//            $0.move(to: P0)
//            $0.addQuadCurve(to: P2, control: P1)
//        }
//
//        return PathText(text: text, path: path)
//    }
//
//
//    static var previews: some View {
//        Group {
//            CurveView()
//            LineView()
//            LinesView()
//            LineAndCurveView()
//            QuadCurveView()
//        }
//    }
//}
