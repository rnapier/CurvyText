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
                return layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 1),
                                                  in: textContainer)
//                let leadingBottom = layoutManager.location(forGlyphAt: glyphIndex).x
//                let rect = layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 1),
//                                                      in: textContainer)
//                return leadingBottom + rect.size.width / 2
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

    private var locations: [CGRect] = []
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

        let tangents = path.getTangents(atLocations: locations.map {$0.origin.x})

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
            let location: CGRect
        }

        var runs: [Run] = []
        for (tangent, (string, location)) in zip(tangents, zip(strings, locations)) {
            runs.append(Run(angle: Double(tangent.angle), point: tangent.point, string: string, location: location))
        }

        // FIXME: include lineFragmentOrigin (but currently it's .zero)

        let baselineShift: CGFloat = 10.0

        return ZStack {
            ForEach(runs) { run in
                Text(verbatim: run.string)
                    .font(.system(size: 48))
                    .padding(EdgeInsets(top: baselineShift, leading: 0, bottom: -baselineShift, trailing: 0))
                    .border(Color.green)
                    .rotationEffect(.radians(run.angle), anchor: .bottomLeading)
                    .offset(x: run.location.width / 2, y: (-run.location.height / 2))
                    .position(run.point)
                Circle()
                    .foregroundColor(.red)
                    .frame(width: 5, height: 5)
                    .position(run.point)
            }
        }
        .border(Color.red)
    }
}


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

        return VStack {
            Text("You can display text along a curve")
                .font(.system(size: 48))
                .padding(.horizontal)
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
