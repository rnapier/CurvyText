//
//  PathText.swift
//  CurvyText
//
//  Created by Rob Napier on 12/6/19.
//  Copyright © 2019 Rob Napier. All rights reserved.
//

import SwiftUI
import CoreText

// Terminology:
//     t: Value from 0 to 1, where 0 is the starting point, and 1 is the final point.
//        Note that t=0.5 does *not* mean "half-way through the curve."
//
//     linearDistance: 1-D distance along the path
//
//     location: a linearDistance from the starting point
//
//     distance: 2-D Eucledian distance

private struct GlyphPosition {
    let attributedString: NSAttributedString
    let baseline: CGFloat
    let rect: CGRect
}

@available(iOS 13.0, *)
public struct PathText {
    public var text: NSAttributedString {
        didSet {
            updatePositions()
        }
    }

    public var path: Path {
        didSet {
            updateRuns()
        }
    }

    private var glyphPositions: [GlyphPosition] = []

    public init(text: NSAttributedString, path: Path) {
        self.path = path
        self.text = text
        updatePositions()
    }

    mutating private func updatePositions() {
        let line = CTLineCreateWithAttributedString(text)

        glyphPositions = line.glyphRuns.flatMap { run -> [GlyphPosition] in
            let baseline = run.font.descender
            return run.glyphCharacterMapping.map { (glyphRange, characterRange) in
                GlyphPosition(attributedString: text.attributedSubstring(from: characterRange),
                              baseline: baseline,
                              rect: run.typographicFrame(glyphRange: glyphRange))
            }
        }
        updateRuns()
    }

    mutating private func updateRuns() {
        let tangents = path.getTangents(atLocations: glyphPositions.map {$0.rect.midX})
        var runs: [Run] = []
        for (tangent, position) in zip(tangents, glyphPositions) {
            runs.append(Run(angle: Double(tangent.angle), point: tangent.point, position: position))
        }
        self.runs = runs
    }

    private struct Run: Identifiable {
        let id = UUID()
        let angle: Double
        let point: CGPoint
        let position: GlyphPosition
    }

    private var runs: [Run] = []

}

@available(iOS 13.0, *)
extension PathText: View {
    public var body: some View {

        // FIXME: include lineFragmentOrigin (but currently it's .zero)

        return ZStack {
            ForEach(runs) { run in
                Text(verbatim: run.position.attributedString.string)
                    .font(.system(size: 48))
                    .padding(EdgeInsets(top: -run.position.baseline, leading: 0, bottom: run.position.baseline, trailing: 0))
//                    .border(Color.green)
                    .rotationEffect(.radians(run.angle), anchor: .bottom)
                    .offset(x: 0, y: (-run.position.rect.height / 2))
                    .position(run.point)
//                Circle()
//                    .foregroundColor(.red)
//                    .frame(width: 5, height: 5)
//                    .position(run.point)
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


    static var previews: some View {
        Group {
            CurveView()
            LineView()
            LinesView()
            LineAndCurveView()
            QuadCurveView()
            RoundedRectView()
        }.previewLayout(.fixed(width: 700, height: 500))
    }
}
