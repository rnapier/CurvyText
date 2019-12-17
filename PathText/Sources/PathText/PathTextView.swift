//
//  PathText.swift
//  CurvyText
//
//  Created by Rob Napier on 12/6/19.
//  Copyright © 2019 Rob Napier. All rights reserved.
//

import SwiftUI
import CoreText

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

private struct GlyphPosition {
    let attributedString: NSAttributedString
    let baseline: CGFloat
    let rect: CGRect
}

@available(iOS 13.0, *)
public struct PathText {
    public var text: NSAttributedString {
        get { NSAttributedString(attributedString: textStorage) }
        set { textStorage.setAttributedString(newValue)
            updatePositions()
        }
    }

    public var path: Path {
        didSet {
            updateRuns()
        }
    }

    public init(text: NSAttributedString, path: Path) {
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        self.path = path
        self.text = text
    }

    private var glyphPositions: [GlyphPosition] = []

    private let layoutManager = NSLayoutManager()
    private let textStorage = NSTextStorage()
    private let textContainer = NSTextContainer()

    private mutating func updatePositions() {

        self.glyphPositions = Array(sequence(state: 0) { [textStorage, layoutManager] (characterIndex) in
            guard characterIndex < textStorage.length else { return nil }

            let string = textStorage.string as NSString
            let characterRange = string.rangeOfComposedCharacterSequence(at: characterIndex)
            var actualCharacterRange = NSRange()
            let glyphRange = layoutManager.glyphRange(forCharacterRange: characterRange,
                                                      actualCharacterRange: &actualCharacterRange)
            assert(characterRange == actualCharacterRange)  // It shouldn't be possible for this to mismatch since we composed the character already

            let glyphString = textStorage.attributedSubstring(from: actualCharacterRange)

            let font = glyphString.attribute(.font, at: 0, effectiveRange: nil) as! PlatformFont    // NSTextStorage always resolves a font.

            let baseline = font.descender

            let line = CTLineCreateWithAttributedString(glyphString)
            let origin = layoutManager.location(forGlyphAt: glyphRange.location)
            let bounds = CTLineGetBoundsWithOptions(line, [])

            let position = GlyphPosition(attributedString: glyphString,
                                         baseline: baseline,
                                         rect: bounds.offsetBy(dx: origin.x, dy: origin.y))

            characterIndex = NSMaxRange(actualCharacterRange)
            return position
        })

        updateRuns()
    }

    mutating private func updateRuns() {
        let tangents = path.getTangents(atLocations: glyphPositions.map {$0.rect.midX})
        self.runs = zip(tangents, glyphPositions).map { tangent, position in
            Run(angle: Double(tangent.angle), point: tangent.point, position: position)
        }
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
        return ZStack {
            ForEach(runs) { run in
                Text(verbatim: run.position.attributedString.string)
                    .attributes(run.position.attributedString.attributes(at: 0, effectiveRange: nil))
                    .frame(width: run.position.rect.size.width, height: run.position.rect.size.height, alignment: .bottom)
                    .padding(EdgeInsets(top: -run.position.baseline, leading: 0, bottom: run.position.baseline, trailing: 0))
                    .rotationEffect(.radians(run.angle), anchor: .bottom)
                    .offset(x: 0, y: (-run.position.rect.height / 2))
                    .position(run.point)
            }
        }
    }
}

@available(iOS 13.0.0, *)
extension Text {
    func attributes(_ attributes: [NSAttributedString.Key : Any]) -> Text {
        var result = self

        for (key, value) in attributes {
            switch key {
            case .font:
                result = result.font(Font(value as! PlatformFont))

            case .foregroundColor:
                result = result.foregroundColor(Color(value as! PlatformColor))

            // A few things to ignore
            case .init("NSOriginalFont"):   // Original font before substitution. We don't care about that.
                break

            default:
                print("Unknown attribute: \(key) = \(value)")   // FIXME: Just for debugging.
                break
            }
        }
        return result
    }
}

@available(iOS 13.0.0, *)
struct PathText_Previews: PreviewProvider {
    static let text: NSAttributedString = {
        let string = NSString("You can d\u{030a}isplay tëxt along a cu\u{0327}rve, with bold, color, and big text.")

        let s = NSMutableAttributedString(string: string as String,
                                          attributes: [.font: UIFont.systemFont(ofSize: 48)])

        s.addAttributes([.font: UIFont.boldSystemFont(ofSize: 16)], range: string.range(of: "bold"))
        s.addAttributes([.foregroundColor: UIColor.red], range: string.range(of: "color"))
        s.addAttributes([.font: UIFont.systemFont(ofSize: 32)], range: string.range(of: "big text"))
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
            Text("x")
            Text("Y͑ͩ̾ͭ̀̓͂oͯ͋ͭͬ̚u̩͐ ̖̙c̪̉ạ̽n ̫̫̳̙̻̩di̎́̓̾̅͊s̲̯̻̳͐̌̋̂̅͂ͅͅpla̺̼̰͚̣̦̣y̺̝͌ͦ ̂͋̓́͗̎̚t̟̩͕͉̐ͦ̎̍ẹ̭̺͓̳͔͈̄ͤͣ̐̑ͦ̀xͥͩ̓̈t͕̭̥͈ͣ̃̍͂̑ͅ a͖̗̿ͨl̉͑̊ͯ̿̆o͍̤̳͕n̫̥̓̾g̈́ a ͚̽c͔̫̪̰̳ͫ̽̀̍̚ur̞̬͎͍͈̙ͩͧ͑ͩ͒̆ve̪̠̼͖̩̤̲̐͗̒̃ͯ̅̽")// "You can display text along a curve")
                .font(.system(size: 48))
                .padding()
                .lineLimit(1)
                .frame(minHeight: 200)
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
