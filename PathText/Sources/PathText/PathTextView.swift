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
public struct PathText {
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
    public var path: Path

    private let layoutManager = NSLayoutManager()
    private let textStorage = NSTextStorage()
    private let textContainer = NSTextContainer()

    private var locations: [CGPoint] = []
    private var lineFragmentOrigin = CGPoint.zero

    public init(text: NSAttributedString, path: Path) {
        self.path = path

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        self.text = text
    }
}

@available(iOS 13.0, *)
extension PathText: View {
    public var body: some View {

        let tangents = path.getTangents(atLocations: locations.map { $0.x })

        var strings: [String] = [] // FIXME: Will be NSAttributedString
        var glyphRange = NSRange(location: 0, length: 1)
        while NSMaxRange(glyphRange) < layoutManager.numberOfGlyphs {
            let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange,
                                                              actualGlyphRange: &glyphRange)
            strings.append(textStorage.attributedSubstring(from: characterRange).string)
            glyphRange = NSRange(location: NSMaxRange(glyphRange), length: 1)
        }

        struct Run: Identifiable {
            let id = UUID()
            let angle: Double
            let point: CGPoint
            let string: String
        }

        let runs = zip(tangents, strings).map { tangent, string in
            Run(angle: Double(tangent.angle), point: tangent.point, string: string)
        }

        // FIXME: include lineFragmentOrigin (but currently it's .zero)

        return ZStack(alignment: .topLeading) {
            Rectangle().foregroundColor(.clear) // FIXME: Making Zstack size of containing view. Easier way?
            ForEach(runs) { run in
//                ZStack(alignment: .topLeading) {
                    Text(verbatim: run.string)
                        .font(.system(size: 48))
                        .border(Color.green)
                        .rotationEffect(.radians(run.angle), anchor: .bottomLeading)
                        .offset(x: run.point.x, y: run.point.y)
                    .alignmentGuide(.top) { d in d[.lastTextBaseline] }
                    //                    .offset(x: 10, y: 10)
                Circle()
                    .foregroundColor(.red)
                    .frame(width: 5, height: 5)
                    .position(run.point)
                }
        }.border(Color.red)
//        }
//        for (index, (tangent, location)) in zip(tangents, locations).enumerated() {
//
//
//            let glyphPoint = tangent.point
//            let angle = tangent.angle
//
//
//            context.translateBy(x: glyphPoint.x, y: glyphPoint.y)
//            context.rotate(by: angle)
//
//            // The "at:" in drawGlyphs is the origin of the line fragment. We've already adjusted the
//            // context, so take that back out.
//            let adjustedOrigin = CGPoint(x: -(lineFragmentOrigin.x + location.x),
//                                         y: -(lineFragmentOrigin.y + location.y))
//
//            layoutManager.drawGlyphs(forGlyphRange: NSRange(location: index, length: 1),
//                                     at: adjustedOrigin)
//
//            context.restoreGState()
//        }
//
//
//
//        Text("Stuff")
    }
}


//@available(iOS 13.0, *)
//public struct PathText: UIViewRepresentable {
//    public var text: NSAttributedString
//    public var path: CGPath
//
//    public init(text: NSAttributedString, path: Path) {
//        self.init(text: text, path: path.cgPath)
//    }
//
//    public init(text: NSAttributedString, path: CGPath) {
//        self.text = text
//        self.path = path
//    }
//
//    public func makeUIView(context: UIViewRepresentableContext<PathText>) -> PathTextView {
//        PathTextView()
//    }
//
//    public func updateUIView(_ uiView: PathTextView, context: UIViewRepresentableContext<PathText>) {
//        uiView.text = text
//        uiView.path = path
//    }
//}

/*
 Draws attributed text along a cubic Bezier path defined by P0, P1, P2, and P3
 */
//public class PathTextView: UIView {
//
//    public var path: CGPath = CGMutablePath() {
//        didSet {
//            setNeedsDisplay()
//        }
//    }
//
//    public var text: NSAttributedString {
//        get { textStorage }
//        set {
//            textStorage.setAttributedString(newValue)
//            locations = (0..<layoutManager.numberOfGlyphs).map { [layoutManager] glyphIndex in
//                layoutManager.location(forGlyphAt: glyphIndex)
//            }
//
//            lineFragmentOrigin = layoutManager
//                .lineFragmentRect(forGlyphAt: 0, effectiveRange: nil)
//                .origin
//        }
//    }
//
//    private let layoutManager = NSLayoutManager()
//    private let textStorage = NSTextStorage()
//    private let textContainer = NSTextContainer()
//
//    private var locations: [CGPoint] = []
//    private var lineFragmentOrigin = CGPoint.zero
//
//    public init() {
//        layoutManager.addTextContainer(textContainer)
//        textStorage.addLayoutManager(layoutManager)
//        super.init(frame: .zero)
//        backgroundColor = .clear
//    }
//
//    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
//
//    public override func draw(_ rect: CGRect) {
//
//        let tangents = path.getTangents(atLocations: locations.map { $0.x })
//
//        let context = UIGraphicsGetCurrentContext()!
//
//        for (index, (tangent, location)) in zip(tangents, locations).enumerated() {
//            context.saveGState()
//
//            let glyphPoint = tangent.point
//            let angle = tangent.angle
//
//            context.translateBy(x: glyphPoint.x, y: glyphPoint.y)
//            context.rotate(by: angle)
//
//            // The "at:" in drawGlyphs is the origin of the line fragment. We've already adjusted the
//            // context, so take that back out.
//            let adjustedOrigin = CGPoint(x: -(lineFragmentOrigin.x + location.x),
//                                         y: -(lineFragmentOrigin.y + location.y))
//
//            layoutManager.drawGlyphs(forGlyphRange: NSRange(location: index, length: 1),
//                                     at: adjustedOrigin)
//
//            context.restoreGState()
//        }
//    }
//}

@available(iOS 13.0.0, *)
struct PathText_Previews: PreviewProvider {
    static let text: NSAttributedString = {
        let string = NSString("You can display text along a curve, with bold, color, and big text.")

        let s = NSMutableAttributedString(string: string as String,
                                          attributes: [.font: UIFont.systemFont(ofSize: 48)])

//        s.addAttributes([.font: UIFont.boldSystemFont(ofSize: 16)], range: string.range(of: "bold"))
//        s.addAttributes([.foregroundColor: UIColor.red], range: string.range(of: "color"))
//        s.addAttributes([.font: UIFont.systemFont(ofSize: 32)], range: string.range(of: "big text"))
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

        return ZStack {PathText(text: text, path: path)
            path.stroke(Color.blue, lineWidth: 2)
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


    static var previews: some View {
        Group {
            CurveView()
            LineView()
            LinesView()
            LineAndCurveView()
            QuadCurveView()
        }.previewLayout(.fixed(width: 700, height: 500))
    }
}
